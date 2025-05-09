{ config, pkgs, lib, ... }:

let cfg = config.services.temporal;
    registry = (import ../../data/service-registry.nix).temporal;
    user = "temporal";
    group = "temporal";
    stateDir = "/var/lib/temporal";
    configDir = "${stateDir}/config";

    # Generate production YAMLs from Nix values
    yaml = pkgs.formats.yaml { };

    prod-ui-config = yaml.generate "production-ui.yaml" {
      enableUi = true;
      temporalGrpcAddress = "127.0.0.1:${toString cfg.ports.api}";
      port = cfg.ports.ui;
    };

    # https://docs.temporal.io/self-hosted-guide/defaults
    #
    # Update those defaults if we want finer control.
    prod-config = yaml.generate "production.yaml" (
      import ./prod-config.nix {
        inherit stateDir;
        inherit (cfg) host ports;
      });

in {
  options.services.temporal = with lib; {
    enable = mkEnableOption "Enable Temporal prod server";

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''
        IP address where Temporal binds its services.
        Use 0.0.0.0 to expose externally.
      '';
    };

    # Sub-module for all required ports
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
        options.pprof = mkOption {
          type = types.port;
          default = registry.ports.pprof;
          description = "The port for pprof (performance monitoring)";
        };
        # Temporal’s server uses a Ringpop gossip protocol for peer discovery;
        # each node listens on its configured membershipPort to join and
        # maintain the cluster ring.
        options.frontendMembership = mkOption {
          type = types.port;
          default = registry.ports.frontendMembership;
          description = "For Ringpop gossip protocol, frontend service";
        };
        options.frontendHttp = mkOption {
          type = types.port;
          default = registry.ports.frontendHttp;
          description = "Similar to ports.api but using HTTP instead of Grpc";
        };
        options.matching = mkOption {
          type = types.port;
          default = registry.ports.matching;
          description = "Main port for the matching service";
        };
        options.matchingMembership = mkOption {
          type = types.port;
          default = registry.ports.matchingMembership;
          description = "For Ringpop gossip protocol, matching service";
        };
        options.history = mkOption {
          type = types.port;
          default = registry.ports.history;
          description = "Main port for the history service";
        };
        options.historyMembership = mkOption {
          type = types.port;
          default = registry.ports.historyMembership;
          description = "For Ringpop gossip protocol, history service";
        };
        options.worker = mkOption {
          type = types.port;
          default = registry.ports.worker;
          description = "Main port for the worker service";
        };

      };
      default = {
        inherit (registry.ports) api ui pprof frontendMembership frontendHttp
          matching matchingMembership history historyMembership worker;
      };
      description = "Ports for Temporal server components.";
    };

    namespaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of Temporal namespaces to ensure exist.
        The built-in "default" namespace is always created.
      '';
      example = [
        "my-namespace"
        "my-other-namespace"
      ];
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to open the ports api (frontend grpc) and ui in the firewall.
      '';
    };

    allowInsecureCookie = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When set to "true", it instructs the UI server to mark its
        CSRF-protection cookie as not requiring the Secure attribute, allowing
        the cookie to be set and sent over plain HTTP connections instead of
        HTTPS. Required if you intended to make the service available via HTTP
        and used only internally.
      '';
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

    # Ensure directories & symlink YAML configs
    systemd.tmpfiles.rules = [
      "d ${stateDir} 755 ${user} ${group} -"
      "d ${configDir} 755 ${user} ${group} -"
      # Link generated YAMLs into /var/lib/temporal/config
      "L+ ${configDir}/production.yaml - - - - ${prod-config}"
      "L+ ${configDir}/production-ui.yaml - - - - ${prod-ui-config}"
    ];

    systemd.services.temporal = {
      # See https://docs.temporal.io/temporal-service
      description = "A single Temporal Service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "temporal-namespaces.service" ];
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

      environment = lib.mkIf cfg.allowInsecureCookie {
        TEMPORAL_CSRF_COOKIE_INSECURE = "true";
        TEMPORAL_CORS_ORIGINS = "*";
      };
    };

    systemd.services.temporal-namespaces = {
      description = "Initialize Temporal namespaces";
      # Ensure it follows the main temporal service
      partOf = [ "temporal.service" ];
      after  = [ "temporal.service" ];
      # binds into temporal.service lifecycle
      wantedBy = [ "temporal.service" ];
      serviceConfig = {
        Type    = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      };
      script = lib.concatStringsSep "\n" (map
        (x: ''
           ${pkgs.temporal-cli}/bin/temporal operator \
               --address "localhost:${toString cfg.ports.api}" \
               namespace describe -n ${x} > /dev/null 2>&1 || \
           ${pkgs.temporal-cli}/bin/temporal operator \
               --address "localhost:${toString cfg.ports.api}" \
               namespace create -n ${x}
         '') ([ "default" ] ++ cfg.namespaces));
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.ports.api
      cfg.ports.ui
    ];
  };
}
