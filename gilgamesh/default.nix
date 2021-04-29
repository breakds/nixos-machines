{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../base
    ./zrw.nix
    # ../modules/services/samba.nix
    # ../modules/services/deluge.nix
    # ../modules/services/nginx.nix
    # ../modules/services/cgit.nix
    # ../modules/services/homepage.nix
    # ../modules/services/gitea.nix
    # ../modules/services/filerun.nix
    # ../modules/services/terraria.nix
    # ../modules/services/jupyter-lab.nix
    # ../modules/services/nix-serve.nix
    # ../modules/services/docker-registry.nix
    # ../modules/dev/python-environment.nix
    # ../containers/declarative/hydrahead.nix
  ];

  config = {
    vital.mainUser = "breakds";

    networking = {
      hostName = "gilgamesh";
      hostId = "7a4bd408";
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    vital.graphical = {
      enable = true;
      xserver.dpi = 100;
      nvidia.enable = true;
      remote-desktop.enable = true;
    };
    
    environment.systemPackages = with pkgs; [
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?
  };
}
