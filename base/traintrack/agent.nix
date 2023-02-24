{ config, lib, pkgs, ... }:

let cfg = config.services.traintrack-agent;

    configFile = pkgs.writeText "agent-config.json" ''
       ${builtins.toJSON cfg.settings}
    '';

in {
  options.services.traintrack-agent = let
    workerConfig = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
      };
      default = {};
      description = lib.mdDoc "Defines the worker for the agent.";
      example = lib.literalExpression ''
        {
          gpu_id = 0;
          gpu_type = "3080";
          repos = {
            Hobot = {
              path = "/home/breakds/projects/Hobot";
              work_dir = "/home/breakds/dataset/alf_sessions";
            };
          };
        }
      '';
    };

  in {
    enable = lib.mkEnableOption "Enable the traintrack agent";

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
      };
      default = { workers = []; };
      description = "Contents of the agent config file";
    };

    port = lib.mkOption {
      description = lib.mdDoc "Traintrack agent API port.";
      default = 5975;
      type = lib.types.port;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "User account under which the agent runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "Group under which the agent runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/traintrack 775 ${cfg.user} ${cfg.group} -"
      "d /var/lib/traintrack/agent 775 ${cfg.user} ${cfg.group} -"
    ];

    environment.etc."traintrack/agent-config.json".source = configFile;

    systemd.services.traintrack-agent = {
      description = "Agent node of traintrack";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.tmux pkgs.git ];

      serviceConfig = {
        ExecStart = "${pkgs.traintrack}/bin/agent";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart= "on-failure";
        RestartSec = "5s";
      };

      environment = {
        TRAINTRACK_AGENT_PORT = toString cfg.port;
        TRAINTRACK_AGENT_CONFIG = "/etc/traintrack/agent-config.json";
      };
    };
  };
}