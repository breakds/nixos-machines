{ config, lib, pkgs, ... }:

let cfg = config.services.famass;

in {
  options.services.famass = {
    enable = lib.mkEnableOption "Enable the famass assistant";

    port = lib.mkOption {
      description = lib.mdDoc "famss port.";
      default = 5928;
      type = lib.types.port;
    };

    dataDir = lib.mkOption {
      description = lib.mdDoc "The path to the data.";
      default = "/home/breakds/dataset/yang";
      type = lib.types.str;
    };

    domain = lib.mkOption {
      description = lib.mdDoc "The domain to expose the service to";
      default = "famass.breakds.org";
      type = lib.types.str;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "User account under which the famass runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "Group under which the famass runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.famass = {
      description = "Famass assistant service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [];

      serviceConfig = {
        ExecStart = "${pkgs.python3Packages.rapit}/bin/famass";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart= "on-failure";
        RestartSec = "1200s";
      };

      environment = {
        FAMASS_APP_DIST_DIR = "${pkgs.famass-webui}";
        FAMASS_DATA_DIR = cfg.dataDir;
        FAMASS_PORT = toString cfg.port;
      };
    };

    services.nginx = {
      virtualHosts = {
        "${cfg.domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:${toString cfg.port}";
            # Enable websockets when needed.
            # proxyWebsockets = true;
          };
        };
      };
    };
  };
}
