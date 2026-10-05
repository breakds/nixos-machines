{ config, lib, pkgs, ... }:

let
  agents = config.vital.coding-agent.enabledAgents;
  enableShepherd = config.vital.coding-agent.shepherd.enable;

in {
  options.vital.coding-agent.enabledAgents = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [ "pi" "codex" "claude" ]);
    default = [ "pi" "codex" "claude" ];
    description = "Coding agents to install and configure.";
  };

  options.vital.coding-agent.shepherd.enable =
    lib.mkEnableOption "Shepherd task submission tools and skill" // {
      default = true;
    };

  config = {
    environment.systemPackages =
      lib.optionals (builtins.elem "claude" agents) [ pkgs.claude-code-bin ]
      ++ lib.optionals (builtins.elem "codex" agents) [ pkgs.codex ]
      ++ lib.optionals enableShepherd [ pkgs.shepherd ]
      ++ lib.optionals (builtins.elem "pi" agents) [ pkgs.pi-coding-agent ];

    programs.skillful = {
      user = "breakds";
      enabledAgents = lib.mkDefault agents;
      skills = [ "nix-scaffolding" ]
        ++ lib.optional enableShepherd "shepherd-submit"
        ++ [ "grill-with-docs" ];
    };

    home-manager.users.breakds = {
      home.file = lib.mkMerge [
        (lib.mkIf (builtins.elem "claude" agents) {
          # User specific claude code configurations
          ".claude/CLAUDE.md".source = ./AGENTS.md;
          ".claude/settings.json".source = ./claude/settings.json;
          ".claude/custom-scripts/statusline-script.sh".source = ./claude/custom-scripts/statusline-script.sh;
          ".claude/sound/cartoon-tiptoe-marimba-om-fx-1-00-03.mp3".source = ./sound/cartoon-tiptoe-marimba-om-fx-1-00-03.mp3;
          ".claude/sound/notification-alert-you-have-mail-zeroframe-audio-1-00-01.mp3".source = ./sound/notification-alert-you-have-mail-zeroframe-audio-1-00-01.mp3;
          ".claude/sound/notification-digital-ting-vadi-sound-1-00-00.mp3".source = ./sound/notification-digital-ting-vadi-sound-1-00-00.mp3;
        })
        (lib.mkIf (builtins.elem "codex" agents) {
          # User specific codex configuration
          ".codex/AGENTS.md".source = ./AGENTS.md;
          # ".codex/config.toml".source = ./codex/config.toml;
        })
      ];
    };
  };
}
