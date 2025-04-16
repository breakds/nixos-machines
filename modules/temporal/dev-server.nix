# This is actually based on `temporal-cli`, which starts a relatively
# light-weight dev server. Use with care for heavy-load produciton scenario.
#
# TODO: Use the actual `temporal` package with UI for deployment. Based on my
# preliminary research, this command can successfully deploy everything but
# without the UI.
#
# ExecStart = ''
#   ${pkgs.temporal}/bin/temporal-server \
#     --env production \
#     --root ${stateDir} \
#     --config "config" \
#     --allow-no-auth=true \
#     start \
#     --service frontend \
#     --service history \
#     --service matching \
#     --service worker
# '';
#
# This config is based on
# https://github.com/cachix/devenv/blob/main/src/modules/services/temporal.nix


{ config, pkgs, lib, ... }:

let cfg = config.services.temporal-dev-server;
    registry = (import ../../data/service-registry.nix).temporal;
    user = "temporal";
    group = "temporal";
    stateDir = "/var/lib/temporal";

    extraArgs = lib.forEach cfg.namespaces (namespace: "--namespace=${namespace}");

in {
  options.services.temporal-dev-server = with lib; {
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
    ids.uids.temporal = registry.uid;
    ids.gids.temporal = registry.gid;
    
    users.groups."${group}" = {
      gid = config.ids.gids.temporal;
    };

    users.users."${user}" = {
      description = "Temporal.io service user";
      group = group;
      home = stateDir;
      useDefaultShell = true;
      uid = config.ids.uids.temporal;
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 755 ${user} ${group} -"
    ];

    systemd.services.temporal-dev-server = {
      description = "The temporal dev server service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = stateDir;
        DynamicUser = false;
        ExecStart = ''
          ${pkgs.temporal-cli}/bin/temporal server start-dev \
              --log-format=pretty \
              --ip=${cfg.host} \
              --port=${toString cfg.ports.api} \
              --ui-ip=${cfg.host} \
              --ui-port=${toString cfg.ports.ui} \
              --db-filename=${stateDir}/dev-server.db \
              --sqlite-pragma journal_mode=wal \
              ${lib.concatStringsSep " " extraArgs}
        '';
        Restart = "on-failure";
        StateDirectory = [ "temporal" ];
      };
    };    
  };
}
