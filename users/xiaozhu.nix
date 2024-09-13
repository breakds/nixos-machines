{ config, lib, pkgs, ... }:

{
  config = {
    users.extraUsers = {
      "xiaozhu" = {
        isNormalUser = true;
	      home = "/home/xiaozhu";
        uid = 1021;
	      description = "Xiaozhu Shen";
        extraGroups = [
          "xiaozhu"
        ];

        openssh.authorizedKeys.keyFiles = [
          ../data/keys/xiaozhu.pub
        ];
      };
    };

    home-manager.users.xiaozhu = {
      home.stateVersion = "23.11";

      home.file = {
        ".inputrc".text = ''
        "\e[A": history-search-backward
        "\e[B": history-search-forward
      '';
      };

      programs.bash = {
        enable = true;

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
        userName = lib.mkDefault "Xiaozhu Shen";
        userEmail = lib.mkDefault "sxz@yytzfund.com";

        extraConfig = {
          pull.rebase = true;
          init.defaultBranch = "main";
          advice.addIgnoredFile = false;
        };
      };
    };
  };
}
