{ config, lib, ... }:

let
  service-registry = (import ../../../../data/service-registry.nix);
  prometheusInfo = service-registry.prometheus;
  nodeExporterPort = prometheusInfo.exporters.node.port;
  nvidiaExporterPort = prometheusInfo.exporters.nvidia-gpu.port;
  
in {
  imports = [
    ./grafana
  ];
  
  config = {
    services.prometheus = {
      enable = true;
      port = prometheusInfo.port;

      exporters = {
        node.enable = true;
        nvidia-gpu.enable = true;
      };
      
      scrapeConfigs = [
        {
          job_name = "kirkwood";
          static_configs = [{
            targets = [
              # e.g. `xh localhost:5821/metrics` to see what is being collected
              "octavian.local:${toString nodeExporterPort}"
              "lorian.local:${toString nodeExporterPort}"
              "radahn.local:${toString nodeExporterPort}"
            ];
          }];
        }

        {
          job_name = "gpu";
          static_configs = [{
            targets = [
              # e.g. `xh localhost:5821/metrics` to see what is being collected
              "octavian.local:${toString nvidiaExporterPort}"
              "lorian.local:${toString nvidiaExporterPort}"
              "radahn.local:${toString nvidiaExporterPort}"
            ];
          }];
        }
      ];
    };
  };
}
