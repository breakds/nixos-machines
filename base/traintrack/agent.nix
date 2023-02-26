{ config, lib, pkgs, ... }:

let cfg = config.services.traintrack-agent;

    configFile = pkgs.writeText "agent-config.json" ''
       ${builtins.toJSON cfg.settings}
    '';

in {
  options.services.traintrack-agent = {
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
