{ config, lib, ... }:

let
  registry = import ../../../../../data/service-registry.nix;
  info = registry.grafana;

in {
  imports = [ ./oauth2.nix ];

  config = {
    age.secrets.grafana-secret-key = {
      file = ../../../../../secrets/grafana-secret-key.age;
      mode = "0400";
      owner = "grafana";
    };

    # NOTE: At the first time you access the grafana instance, the username and
    # password is both admin. After login you will be forced to change the
    # password for admin.
    services.grafana = {
      enable = true;

      settings.server = {
        domain = info.domain;
        http_addr = "127.0.0.1";
        http_port = info.port;
        # The public URL behind nginx. Without it Grafana derives
        # http://<domain>:<port>/ and sends that as the OAuth redirect_uri,
        # which kanidm rejects (exact-match against the registered https URL).
        root_url = "https://${info.domain}/";
      };

      # Rotated away from the historical hardcoded value (public in git
      # history). Nothing encrypted with the old key existed at rotation
      # time — the only provisioned datasource carries no credentials.
      settings.security.secret_key =
        "$__file{${config.age.secrets.grafana-secret-key.path}}";

      provision.datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:${toString config.services.prometheus.port}";
      }];

      # Note: not using provision for reproducible dashboards and alerts at this
      # moment, but their jsons are committed anyway for future improvements.
    };

    services.nginx = {
      virtualHosts = {
        "${config.services.grafana.settings.server.domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:${
                toString config.services.grafana.settings.server.http_port
              }";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
