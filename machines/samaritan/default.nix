{ lib, config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../base/dev/realsense.nix
    ../../base/traintrack/agent.nix
    ../../base/build-machines.nix
    ../../modules/syncthing.nix
    ./services/monitor.nix
    ../../base/dev/interbotix.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
      extraGroups = [
        "dialout"
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Internationalisation
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
      hostName = "samaritan";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9c4a63a8";

      # WakeOnLan. You will need to know the ip and mac of this
      # machines to be able to wake it. The command that you should
      # run on the other machine should be:
      #
      #     wol -i <ip> <mac>
      interfaces."enp6s0".wakeOnLan.enable = true;
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;

    environment.systemPackages = with pkgs; [
      robot-deployment-suite
      gimp
      darktable
      go-ethereum
      filezilla
      woeusb
      axel
      audacious
      audacity
      zoom-us
      thunderbird
      mullvad-vpn
      unetbootin
      trezor-suite
      inkscape
      element-desktop
      rtorrent
      colmena
      anki
      omniverse-launcher
    ];

    vital.distributed-build = {
      enable = true;
      location = "lab";
    };

    networking.firewall.allowedTCPPorts = [ 16006 ];
    networking.firewall.allowedUDPPorts = [ 8030 ];

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    services.traintrack-agent = {
      enable = false;
      port = (import ../../data/service-registry.nix).traintrack.agents.samaritan.port;
      user = "breakds";
      group = "breakds";
      settings = {
        workers = [
          # Worker 0 with 3080
          {
            gpu_id = 0;
            gpu_type = "3080";
            repos = {
              Hobot = {
                path = "/var/lib/traintrack/agent/Hobot0";
                work_dir = "/home/breakds/dataset/alf_sessions";
              };
            };
          }
        ];
      };
    };

    # Disable unified cgroup hierarchy (cgroups v2)
    # This is to applease nvidia-docker
    systemd.enableUnifiedCgroupHierarchy = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "22.05";
  };
}
