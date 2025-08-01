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
              "brock.local:${toString nodeExporterPort}"
              "malenia.local:${toString nodeExporterPort}"
            ];
          }];
        }

        {
          # Just use this dashboard
          # https://grafana.com/grafana/dashboards/14574-nvidia-gpu-metrics/
          job_name = "gpu";
          static_configs = [{
            targets = [
              # e.g. `xh localhost:5824/metrics` to see what is being collected
              "octavian.local:${toString nvidiaExporterPort}"
              "lorian.local:${toString nvidiaExporterPort}"
              "radahn.local:${toString nvidiaExporterPort}"
            ];
          }];
        }

        {
          job_name = "hydra";
          relabel_configs = [{
            source_labels = [ "project" "jobset" "job" ];
            regex = "(.+);(.+);(.+)";  # Capture the labels above
            replacement = "/job/\${1}/\${2}/\${3}/prometheus"; # Use the captured labels
            # "__metrics_path__" instruct scraper to use the replacement instead.
            target_label = "__metrics_path__";
          }];
          static_configs = let mkTarget = { project, jobset ? "main", job }: {
            targets = [ "hydra.breakds.org" ];
            labels = { inherit project jobset job; };
          }; in [
            (mkTarget { project = "ml-pkgs"; job = "gen-ai"; })
            (mkTarget { project = "ml-pkgs"; job = "tools"; })
            (mkTarget { project = "nixos-machines"; job = "octavian"; })
          ];
        }
      ];
    };
  };
}
