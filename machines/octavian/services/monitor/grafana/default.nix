{ config, lib, ... }:

let info = (import ../../../../../data/service-registry.nix).grafana;

in {
  config = {
    # NOTE: At the first time you access the grafana instance, the username and
    # password is both admin. After login you will be forced to change the
    # password for admin.
    services.grafana = {
      enable = true;

      settings.server = {
        domain = info.domain;
        http_addr = "127.0.0.1";
        http_port = info.port;
      };

      provision.datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
      ];

      # Note: not using provision for reproducible dashboards and alerts at this
      # moment, but their jsons are committed anyway for future improvements.
    };

    services.nginx = {
      virtualHosts = {
        "${config.services.grafana.settings.server.domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
