{ config, lib, pkgs, ... }:

{
  config = {
    users.extraUsers = {
      "mujun" = {
        isNormalUser = true;
        initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	      home = "/home/mujun";
        uid = 1022;
	      description = "Mujun Liu";
        extraGroups = [
          "mujun"
        ];

        openssh.authorizedKeys.keyFiles = [
          ../data/keys/mujun_liu.pub
        ];
      };
    };

    home-manager.users.mujun = {
      home.stateVersion = "24.05";

      home.file = {
        ".inputrc".text = ''
        "\e[A": history-search-backward
        "\e[B": history-search-forward
      '';
      };

      programs.bash = {
        enable = true;

        sessionVariables = {
          EDITOR = "emacs";
        };

        bashrcExtra = ''
          # If PS1 is not set, it suggests a non-interactive shell (e.g. scp).
          # Return immediately
          if [ -z "$PS1" ]; then
             return
          fi

          export PS1="\[\033[38;5;81m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;214m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\] {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} \\$ \[$(tput sgr0)\]"

          ${pkgs.fastfetch}/bin/fastfetch
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
        userName = lib.mkDefault "Mujun Liu";
        userEmail = lib.mkDefault "musan@lmj";

        extraConfig = {
          pull.rebase = true;
          init.defaultBranch = "main";
          advice.addIgnoredFile = false;
        };
      };
    };
  };
}
