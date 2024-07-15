{ config, lib, pkgs, ... }:

{
  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };

    home-manager.users.horizon = {
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
      };
    };
  };
}
