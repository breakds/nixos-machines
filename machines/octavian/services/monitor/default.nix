{ config, lib, ... }:

let
  service-registry = (import ../../../../data/service-registry.nix);
  prometheusInfo = service-registry.prometheus;
  nodeExporterPort = prometheusInfo.exporters.node.port;
  
in {
  imports = [
    ./grafana
  ];
  
  config = {
    services.prometheus = {
      enable = true;
      port = prometheusInfo.port;
      exporters.node.enable = true;
      scrapeConfigs = [
        {
          job_name = "kirkwood";
          static_configs = [{
            targets = [
              "octavian.local:${toString nodeExporterPort}"
              "lorian.local:${toString nodeExporterPort}"
              "radahn.local:${toString nodeExporterPort}"
            ];
          }];
        }
      ];
    };
  };
}
