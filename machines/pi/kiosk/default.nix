{ config, pkgs, lib, modulesPath, ... }:

let
  mediaDir = "/var/lib/kiosk-media";

  playlist = pkgs.writeText "kiosk-playlist.txt" ''
    ${mediaDir}/dr_kevin_stephanoff.mp4
    ${mediaDir}/jack_stephens.mp4
    ${mediaDir}/kiosk_slides.mp4
  '';

  # Wrapper that idles until all expected media files exist, then runs mpv,
  # and re-runs mpv (after a short sleep) if it ever exits. Without this,
  # an empty media dir on first boot would cause mpv to exit immediately and
  # cage would die with no recovery.
  kioskRunner = pkgs.writeShellScript "kiosk-runner" ''
    set -u
    while true; do
      if [[ -s "${mediaDir}/dr_kevin_stephanoff.mp4" \
         && -s "${mediaDir}/jack_stephens.mp4" \
         && -s "${mediaDir}/kiosk_slides.mp4" ]]; then
        echo "kiosk-runner: starting mpv"
        ${pkgs.mpv}/bin/mpv \
          --fullscreen \
          --loop-playlist=inf \
          --no-osc \
          --no-input-default-bindings \
          --cursor-autohide=always \
          --hwdec=auto-safe \
          --playlist=${playlist}
        echo "kiosk-runner: mpv exited; restarting in 5s"
      else
        echo "kiosk-runner: waiting for media files in ${mediaDir}"
      fi
      sleep 5
    done
  '';

in {
  imports = [
    ../common.nix
    # Provides the `system.build.sdImage` attribute that builds a flashable
    # .img.zst, plus the matching root/firmware fileSystems definitions.
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  # +------------------------------+
  # | Hardware                     |
  # +------------------------------+

  # We use the Pi-downstream `linux-rpi` kernel (nixos-hardware's mkDefault)
  # rather than mainline because the downstream kernel ships the
  # `bcm2835-codec` V4L2 M2M driver, which is the only way to get hardware
  # H.264 decoding on the Pi 4. Without it we fall back to software decode
  # and the CPU can't keep up with 4K.
  #
  # The reason this needs special care: the upstream `profiles/base.nix`
  # (pulled in via sd-image-aarch64) contributes a kitchen-sink
  # `boot.initrd.availableKernelModules` listing modules from many ARM
  # platforms (Rockchip, Allwinner, Synopsys, Analogix). The Pi kernel
  # doesn't build those, and the modules-shrunk step fails at modprobe.
  # We mkForce the list down to a Pi-4 minimal set.
  boot.initrd.availableKernelModules = lib.mkForce [
    "pcie-brcmstb"      # Pi 4's PCIe (the USB3 controller sits on it)
    "reset-raspberrypi" # VL805 firmware loader
    "mmc_block"         # SD card block layer
    "sdhci-iproc"       # Pi 4 SDHCI controller
    "xhci_hcd"          # USB3
    "xhci_pci"          # USB3
    "usb_storage"
    "uas"
    "usbhid"
    "hid_generic"
    "vc4"               # KMS console (also early modesetting for cage)
  ];

  # FKMS overlay applies to downstream-kernel DTBs (which still expose &fb
  # and &firmwarekms). Enables both firmwarekms and vc4 DRM drivers; cage's
  # wlroots picks the vc4 device. Required to get any modesetting on the
  # downstream kernel — without an overlay, vc4 is disabled in the DT.
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  # The sd-image-aarch64 profile already wires up `/` (NIXOS_SD label) and
  # `/boot/firmware` (FIRMWARE label), so we only override mount options.
  fileSystems."/".options = [ "noatime" ];

  # Upstream nixos/modules/profiles/base.nix (pulled in via sd-image-aarch64)
  # enables ZFS by default; we don't need it on an SD-card kiosk and skipping
  # it avoids a long out-of-tree zfs-kernel build.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # PipeWire replaces the deprecated PulseAudio path used in armlet.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Stop the framebuffer console from blanking before cage takes over.
  boot.kernelParams = [ "consoleblank=0" ];

  # +------------------------------+
  # | Networking                   |
  # +------------------------------+

  networking = {
    hostName = "kiosk";
    hostId = "be41ff05";
    networkmanager.enable = true;
    # NetworkManager owns the WiFi radio, so leave wpa_supplicant off.
    wireless.enable = false;
  };

  # +------------------------------+
  # | Users                        |
  # +------------------------------+

  vital.mainUser = "breakds";

  # Dedicated unprivileged user that cage logs in as.
  users.users.kiosk = {
    isNormalUser = true;
    home = "/var/lib/kiosk";
    createHome = true;
    extraGroups = [ "video" "audio" "render" ];
  };

  # Lets breakds reach NetworkManager via nmcli/nmtui without sudo.
  users.users.breakds.extraGroups = [ "networkmanager" ];

  # SSH key auth is the only way in (no passwords are ever set), so requiring
  # a password for sudo just leaves the wheel user permanently locked out of
  # escalation. The security boundary is the SSH key.
  security.sudo.wheelNeedsPassword = false;

  # +------------------------------+
  # | Media directory              |
  # +------------------------------+

  # Created at boot; populate over scp:
  #   scp *.mp4 breakds@kiosk:/var/lib/kiosk-media/
  # Group-writable by `wheel` so breakds can drop new media without sudo.
  systemd.tmpfiles.rules = [
    "d ${mediaDir} 2775 kiosk wheel -"
  ];

  # +------------------------------+
  # | Kiosk session                |
  # +------------------------------+

  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${kioskRunner}";
  };

  # Upstream cage.nix sets no Restart policy, so a crash leaves the screen
  # dead until manual intervention. Make it self-heal.
  systemd.services."cage-tty1".serviceConfig = {
    Restart = "always";
    RestartSec = 5;
    StartLimitIntervalSec = 0;
  };

  # +------------------------------+
  # | Packages                     |
  # +------------------------------+

  environment.systemPackages = with pkgs; [
    vim git tmux mpv
  ];

  system.stateVersion = "25.11";
}
