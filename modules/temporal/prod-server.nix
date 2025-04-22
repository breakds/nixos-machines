{ config, pkgs, lib, ... }:

let cfg = config.services.temporal;
    registry = (import ../../data/service-registry.nix).temporal;
    user = "temporal";
    group = "temporal";
    stateDir = "/var/lib/temporal";
    configDir = "${stateDir}/config";

    yaml = pkgs.formats.yaml { };
    prod-ui-config = yaml.generate "production-ui.yaml" {
      enableUi = true;
      temporalGrpcAddress = "127.0.0.1:${toString cfg.ports.api}";
      port = cfg.ports.ui;
    };

in {
  options.services.temporal = with lib; {
    enable = mkEnableOption "Enable Temporal dev server";

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        The ip to bind. Bind to 0.0.0.0 if you want to expose the service
        to clients that are not on localhost.
      '';
    };

    ports = mkOption {
      type = types.submodule {
        options.api = mkOption {
          type = types.port;
          default = registry.ports.api;
          description = "The port on which the Temporal API listens.";
        };
        options.ui = mkOption {
          type = types.port;
          default = registry.ports.ui;
          description = "The port on which the Temporal Web UI listens.";
        };
      };
      default = {
        api = registry.ports.api;
        ui = registry.ports.ui;
      };
      description = "Specify the ports for components of the temporal dev server.";
    };

    namespaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
          Specify namespaces that should be pre-created (namespace
          \"default\" is always created).
      '';
      example = [
        "my-namespace"
        "my-other-namespace"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups."${group}" = {
      gid = registry.gid;
    };

    users.users."${user}" = {
      description = "Temporal.io service user";
      group = group;
      home = stateDir;
      useDefaultShell = true;
      uid = registry.uid;
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 755 ${user} ${group} -"
      "d ${configDir} 755 ${user} ${group} -"
      "L+ ${configDir}/production.yaml - - - - ${./production.yaml}"
      "L+ ${configDir}/production-ui.yaml - - - - ${prod-ui-config}"
    ];

    systemd.services.temporal = {
      # See https://docs.temporal.io/temporal-service
      description = "A single Temporal Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = stateDir;
        DynamicUser = false;
        ExecStart = ''
          ${pkgs.temporal}/bin/temporal-server \
              --env production \
              --root ${stateDir} \
              --config "config" \
              --allow-no-auth=true \
              start \
              --service frontend \
              --service history \
              --service matching \
              --service worker
        '';
      };
    };

    systemd.services.temporal-ui = {
      # See https://docs.temporal.io/temporal-service
      description = "Temporal service UI";
      wantedBy = [ "multi-user.target" ];
      after = [ "temporal.service" ];
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = stateDir;
        DynamicUser = false;
        ExecStart = ''
          ${pkgs.temporal-ui-server}/bin/server \
              --env production-ui \
              --root ${stateDir} \
              --config "config" \
              start
        '';
      };
    };
  };
}
