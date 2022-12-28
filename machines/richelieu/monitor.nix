{ config, lib, ... }:

{
  # NOTE: At the first time you access the grafana instance, the
  # username and password is both admin. After login you will be
  # forced to change the password for admin.
  services.grafana = {
    enable = true;

    settings.server = {
      domain = "grafana.breakds.org";
      http_addr = "127.0.0.1";
      http_port = 5810;
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
    port = 5820;

    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" "cpu" "filesystem" ];
      port = 5821;
    };

    scrapeConfigs = [
      {
        job_name = "richelieu";
        static_configs = [{
          targets = [ "richelieu.local:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };
}
