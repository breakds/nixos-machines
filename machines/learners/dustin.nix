{ config, lib, pkgs, ... }:

{
  config = {
    users.extraUsers = {
      "dustin" = {
        isNormalUser = true;
        initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	      home = "/home/dustin";
        uid = 1020;
	      description = "Dustin Miao";
        extraGroups = [
          "dustin"
        ];

        openssh.authorizedKeys.keyFiles = [
          ../../data/keys/dustin.pub
        ];
      };
    };

    home-manager.users.dustin = {
      home.stateVersion = "23.11";

      home.file = {
        ".inputrc".text = ''
        "\e[A": history-search-backward
        "\e[B": history-search-forward
      '';
      };

      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv = {
          enable = true;
        };
      };

      programs.git = {
        enable = true;
        package = lib.mkDefault pkgs.gitAndTools.gitFull;
        userName = lib.mkDefault "Dustin Miao";
        userEmail = lib.mkDefault "dmiao0107@gmail.com";

        extraConfig = {
          pull.rebase = true;
          init.defaultBranch = "main";
          advice.addIgnoredFile = false;
        };
      };
    };
  };
}
