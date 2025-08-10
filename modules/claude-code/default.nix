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
        ".claude/commands/python-ready.md".source = ./commands/python-ready.md;
        ".claude/commands/web-ready.md".source = ./commands/web-ready.md;
      };
    };
  };
}
