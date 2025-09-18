{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      claude-code codex
    ];

    home-manager.users.breakds = {
      home.file = {
        # User specific claude code configurations
        ".claude/CLAUDE.md".source = ./AGENTS.md;
        ".claude/settings.json".source = ./claude/settings.json;
        ".claude/commands/prime.md".source = ./claude/commands/prime.md;
        ".claude/commands/python-ready.md".source = ./claude/commands/python-ready.md;
        ".claude/commands/web-ready.md".source = ./claude/commands/web-ready.md;
        ".claude/custom-scripts/statusline-script.sh".source = ./claude/custom-scripts/statusline-script.sh;
        ".claude/sound/cartoon-tiptoe-marimba-om-fx-1-00-03.mp3".source = ./sound/cartoon-tiptoe-marimba-om-fx-1-00-03.mp3;
        ".claude/sound/notification-alert-you-have-mail-zeroframe-audio-1-00-01.mp3".source = ./sound/notification-alert-you-have-mail-zeroframe-audio-1-00-01.mp3;
        ".claude/sound/notification-digital-ting-vadi-sound-1-00-00.mp3".source = ./sound/notification-digital-ting-vadi-sound-1-00-00.mp3;

        # User specific codex configuration
        ".codex/AGENTS.md".source = ./AGENTS.md;
        ".codex/config.toml".source = ./codex/config.toml;
      };
    };
  };
}
