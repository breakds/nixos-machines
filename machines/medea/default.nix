{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    networking = {
      hostName = "medea";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9d5e62c8";
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      xserver.displayManager = "lightdm";
    };

    services.xserver.desktopManager = {
      gnome.enable = lib.mkForce false;
      surf-display.enable = true;
      pantheon.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;
    vital.programs.texlive.enable = false;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = false;
    vital.programs.vscode.enable = false;

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
