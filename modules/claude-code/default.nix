{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      claude-code
    ];
    
    # User specific claude code configurations
    home-manager.users.breakds = {
      home.file = {
        ".claude/CLAUDE.md".source = ./CLAUDE.md;
        ".claude/settings.json".source = ./settings.json;
        ".claude/commands/prime.md".source = ./commands/prime.md;
      };
    };
  };
}
