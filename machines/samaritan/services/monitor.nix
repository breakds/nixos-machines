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
      domain = "grafana.samaritan.local";
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
        job_name = "gail";
        static_configs = [{
          targets = [
            "localhost:${toString config.services.prometheus.exporters.node.port}"
            "radahn.breakds.org:5821"
          ];
        }];
      }
    ];
  };
}
