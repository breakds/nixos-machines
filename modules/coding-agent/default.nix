{ config, lib, pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      claude-code-bin
      # TODO: Re-enable codex once nixpkgs PR #486983 (fetch-cargo-vendor-util fix) reaches nixpkgs-unstable
      # codex
    ];

    home-manager.users.breakds = {
      home.file = {
        # User specific claude code configurations
        ".claude/CLAUDE.md".source = ./AGENTS.md;
        ".claude/settings.json".source = ./claude/settings.json;
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
