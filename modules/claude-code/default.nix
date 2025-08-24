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
        ".claude/custom-scripts/statusline-script.sh".source = ./custom-scripts/statusline-script.sh;
        ".claude/sound/cartoon-tiptoe-marimba-om-fx-1-00-03.mp3".source = ./sound/cartoon-tiptoe-marimba-om-fx-1-00-03.mp3;
        ".claude/sound/notification-alert-you-have-mail-zeroframe-audio-1-00-01.mp3".source = ./sound/notification-alert-you-have-mail-zeroframe-audio-1-00-01.mp3;
        ".claude/sound/notification-digital-ting-vadi-sound-1-00-00.mp3".source = ./sound/notification-digital-ting-vadi-sound-1-00-00.mp3;
      };
    };
  };
}
