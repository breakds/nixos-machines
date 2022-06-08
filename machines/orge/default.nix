{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
      shell = pkgs.zsh;
    };

    # Machine-specific networking configuration.
    networking.hostName = "orge";
    networking.hostId = "aab58b7c";

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;
    vital.programs.arduino.enable = true;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;
    vital.programs.vscode.enable = false;

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      nvidia.enable = true;
      nvidia.prime = {
        enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };

      # Nvidia Prime only works with sddm (not gdm).
      xserver = {
        displayManager = "sddm";
        dpi = 100;
      };
    };

    # This laptop's Nvidia Driver needs persistenced set.
    hardware.nvidia = {
      nvidiaPersistenced = true;
    };

    environment.systemPackages = with pkgs; [
      fbreader
      zoom-us
      thunderbird
      trezor-suite
      unetbootin
    ];

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    # Disable unified cgroup hierarchy (cgroups v2)
    # This is to applease nvidia-docker
    systemd.enableUnifiedCgroupHierarchy = false;

    nix = {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "richelieu";
          systems = [ "x86_64-linux" "i686-linux" ];
          maxJobs = 24;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
      ];
      settings = {
        trusted-substituters = [ "ssh://richelieu.local" ];
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.11"; # Did you read the comment?
  };
}
