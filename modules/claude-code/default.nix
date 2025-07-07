{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      claude-code
    ];
    
    # User specific claude code configurations
    home-manager.users.breakds = {
      home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;
    };
  };
}
