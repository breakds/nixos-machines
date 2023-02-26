{ config, lib, pkgs, ... }:

let cfg = config.services.traintrack-central;

    configFile = pkgs.writeText "central-config.json" ''
       ${builtins.toJSON cfg.settings}
    '';

in {
  options.services.traintrack-central = {
    enable = lib.mkEnableOption "Enable the traintrack central";

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
      };
      default = {};
      description = "Contents of the central config file";
    };

    port = lib.mkOption {
      description = lib.mdDoc "Traintrack central API port.";
      default = 5976;
      type = lib.types.port;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "User account under which the central runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "Group under which the central runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/traintrack 775 ${cfg.user} ${cfg.group} -"
      "d /var/lib/traintrack/central 775 ${cfg.user} ${cfg.group} -"
    ];

    environment.etc."traintrack/central-config.json".source = configFile;

    systemd.services.traintrack-central = {
      description = "Central node of traintrack";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.openssh ];

      serviceConfig = {
        ExecStart = "${pkgs.traintrack}/bin/central";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart= "on-failure";
        RestartSec = "5s";
      };

      environment = {
        TRAINTRACK_CENTRAL_PORT = toString cfg.port;
        TRAINTRACK_CENTRAL_CONFIG = "/etc/traintrack/central-config.json";
      };
    };
  };
}
