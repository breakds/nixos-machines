{ config, pkgs, lib, ... }:

let cfg = config.services.temporal;
    registry = (import ../../data/service-registry.nix).temporal;
    user = "temporal";
    group = "temporal";
    configDir = "${cfg.home}/config";

in {
  options.services.temporal = {
    enable = lib.mkEnableOption "Enable Temporal server service";

    # Directories and configuration
    home = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/temporal";
      description = "The directory where Temporal stores its persistent state.";
    };

    ports = lib.mkOption {
      type = lib.types.submodule {
        options.api = lib.mkOption {
          type = lib.types.port;
          default = registry.ports.api;
          description = "The port on which the Temporal API (backend) listens.";
        };
        options.ui = lib.mkOption {
          type = lib.types.port;
          default = registry.ports.ui;
          description = "The port on which the Temporal Web UI listens.";
        };
        options.metrics = lib.mkOption {
          type = lib.types.port;
          default = registry.ports.metrics;
          description = "The port on which the Temporal metrics endpoint is exposed.";
        };
      };
      default = {
        api = registry.ports.api;
        ui = registry.ports.ui;
        metrics = registry.ports.metrics;
      };
      description = "Specify the ports for various components of the temporal clsuter.";
    };
  };

  config = lib.mkIf cfg.enable {
    ids.uids.temporal = registry.uid;
    ids.gids.temporal = registry.gid;
    
    users.groups."${group}" = {
      gid = config.ids.gids.temporal;
    };

    users.users."${user}" = {
      description = "Temporal.io service user";
      group = group;
      home = cfg.home;
      useDefaultShell = true;
      uid = config.ids.uids.temporal;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.home} 755 ${user} ${group} -"
      "d ${configDir} 755 ${user} ${group} -"
      "L+ ${configDir}/production.yaml - - - - ${./production.yaml}"
    ];

    systemd.services.temporal = {
      description = "The temporal service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = cfg.home;
        DynamicUser = false;
        ExecStart = ''
          ${pkgs.temporal}/bin/temporal-server \
            --env production \
            --root ${cfg.home} \
            --config "config" \
            --allow-no-auth=true \
            start \
            --service frontend \
            --service history \
            --service matching \
            --service worker
        '';
        Restart = "on-failure";
        StateDirectory = [ "temporal" ];
      };
    };    
  };
}
