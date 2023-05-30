{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../base/traintrack/agent.nix    
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    users.users."root" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Use the shiny linux kernel 6.1 for the Ryzen 9 7950x.
    boot.kernelPackages = pkgs.linuxPackages_6_1;
    hardware.nvidia.package = pkgs.linuxPackages_6_1.nvidiaPackages.stable;

    networking = {
      hostName = "malenia";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9cfcdd52";
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = true;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;
    vital.programs.machine-learning.enable = true;

    environment.systemPackages = with pkgs; [
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
      parsec-bin  # For game streaming
      # python3Packages.archer
      blender
      openconnect
    ];

    nix = {
      settings = {
        trusted-users = [ "root" ];
        trusted-substituters = [
          "ssh://octavian.local"
        ];
      };
    };

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    services.traintrack-agent = {
      enable = true;
      port = (import ../../data/service-registry.nix).traintrack.agents.malenia.port;
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
    system.stateVersion = "22.05";
    home-manager.users."breakds".home.stateVersion = "22.05";
  };
}
