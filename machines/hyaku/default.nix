{ lib, config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/dev/realsense.nix
    ../../base/build-machines.nix
    ../../modules/syncthing.nix
    ../../base/dev/interbotix.nix
    ../../modules/steam.nix
  ];

  config = {
    vital.mainUser = "horizon";

    users.users."horizon" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
        ../../data/keys/lezhao.pub
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    i18n.defaultLocale = "en_US.utf8";

    # Enable sound with pipewire.
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    networking = {
      hostName = "hyaku";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9862e28b";
    };

    vital.graphical = {
      enable = true;
      nvidia = {
        enable = true;
        prime = {
          enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
      remote-desktop.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.vscode.enable = false;  # Rely on home manager's.
    vital.programs.texlive.enable = false;
    vital.programs.modern-utils.enable = true;

    environment.systemPackages = with pkgs; [
      zoom-us
      meld
      graphviz
      wireshark
      websocat
      shuriken
      ffmpeg-full
    ];

    vital.distributed-build = {
      enable = true;
      location = "lab";
    };

    networking.firewall.allowedTCPPorts = [ 16006 ];

    # This follows olmokramer's solution from this post:
    # https://discourse.nixos.org/t/configuring-caps-lock-as-control-on-console/9356/2
    services.udev.extraHwdb = ''
      evdev:input:b0003v0B05p19B6e0110*
        KEYBOARD_KEY_70039=leftctrl    # CAPSLOCK -> CTRL
    '';

    programs.nix-ld.enable = true;
    programs.zsh.enable = true;

    # Disable unified cgroup hierarchy (cgroups v2)
    # This is to applease nvidia-docker
    systemd.enableUnifiedCgroupHierarchy = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.05"; # Did you read the comment?
    home-manager.users."horizon".home.stateVersion = "23.05";
  };
}
