{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../base
    # ../../modules/dev/vscode.nix
  ];

  config = {
    vital.mainUser = "cassandra";

    networking = {
      hostName = "welderhelper";
      hostId = "6b6980fa";
    };    

    vital.graphical.enable = true;
    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    environment.systemPackages = with pkgs; [
      gimp peek gnupg pass libreoffice
      nodejs-12_x
      skypeforlinux
    ];

    # This value determines the NixOS release from which the default settings
    # for stateful data, like file locations and database versions on your
    # system were taken. It‘s perfectly fine and recommended to leave this value
    # at the release version of the first install of this system. Before
    # changing this value read the documentation for this option (e.g. man
    # configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?
  };
}
