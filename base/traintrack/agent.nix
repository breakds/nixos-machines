{ config, lib, pkgs, ... }:

let cfg = config.services.traintrack-agent;

    configFile = pkgs.writeText "agent-config.json" ''
    {
      "workers": ${builtins.toJson cfg.workers}
    }
    '';

in {
  options.services.traintrack-agent = let
    workerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = lib.mdDoc "Defines the worker for the agent.";
      example = literalExpression ''
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

    workers = lib.mkOption {
      type = with lib.types; listOf workerConfig;
      default = [];
      description = lib.mdDoc "A list of workers for this agent.";
      example = literalExpression ''
        [{
          gpu_id = 0;
          gpu_type = "3080";
          repos = {
            Hobot = {
              path = "/home/breakds/projects/Hobot1";
              work_dir = "/home/breakds/dataset/alf_sessions";
            };
          };
        }, {
          gpu_id = 1;
          gpu_type = "3080";
          repos = {
            Hobot = {
              path = "/home/breakds/projects/Hobot2";
              work_dir = "/home/breakds/dataset/alf_sessions";
            };
          };
        }]
      '';
    };

    port = mkOption {
      description = lib.mdDoc "Traintrack agent API port.";
      default = 5975;
      type = types.port;
    };

    user = mkOption {
      type = types.str;
      default = "breakds";
      description = lib.mdDoc "User account under which the agent runs.";
    };

    group = mkOption {
      type = types.str;
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

      serviceConfig = {
        ExecStart = "${pkgs.traintrack}/bin/agent";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart= "on-failure";
        RestartSec = "5s";
      };

      environment = {
        TRAINTRACK_AGENT_PORT = cfg.port;
        TRAINTRACK_AGENT_CONFIG = "/etc/traintrack/agent-config.json";
      };
    };
  };
}
