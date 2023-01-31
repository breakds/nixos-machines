{ config, lib, ... }:

let service-registry = (import ../../../data/service-registry.nix);
    grafanaInfo = service-registry.grafana;
    prometheusInfo = service-registry.prometheus;

in {
  # NOTE: At the first time you access the grafana instance, the
  # username and password is both admin. After login you will be
  # forced to change the password for admin.
  services.grafana = {
    enable = true;

    settings.server = {
      domain = grafanaInfo.domain;
      http_addr = "127.0.0.1";
      http_port = grafanaInfo.port;
    };

    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:${toString config.services.prometheus.port}";
      }
    ];
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

  services.prometheus = {
    enable = true;
    port = prometheusInfo.port;

    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" "cpu" "filesystem" ];
      port = prometheusInfo.nodePort;
    };

    scrapeConfigs = [
      {
        job_name = "richelieu";
        static_configs = [{
          targets = [
            "octavian.local:${toString config.services.prometheus.exporters.node.port}"
            "richelieu.local:5821"
            "lorian.local:5821"
            "lothric.local:5821"
            "armlet.local:5821"
          ];
        }];
      }
    ];
  };
}
