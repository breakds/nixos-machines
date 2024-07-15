{ config, lib, pkgs, ... }:

{
  config = {
    users.extraUsers = {
      "mito" = {
        isNormalUser = true;
        home = "/home/mito";
        uid = 4090;
        description = "mito.archaea";
        extraGroups = [
          "wheel"
        ];
        openssh.authorizedKeys.keyFiles = [
          ../../data/keys/breakds_samaritan.pub
        ];
      };
    };
    
    home-manager.users.mito = {
      home.stateVersion = "23.05";
      
      imports = [
        ./git.nix
        ./wezterm.nix
      ];

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

      programs.vscode = {
        enable = true;
        extensions = with pkgs.vscode-extensions; [
          dracula-theme.theme-dracula
          yzhang.markdown-all-in-one
        ];
      };

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        defaultOptions = [ "--height 50%" "--border" ];
      };

      programs.ssh = {
        enable = true;
        hashKnownHosts = true;
        controlMaster = "auto";
        controlPersist = "10m";

        matchBlocks = {
          "*" = {
            identityFile = "~/.ssh/githuber_breakds";
          };
        };
      };
    };
  };
}
