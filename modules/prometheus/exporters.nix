# Note that the idea here is that the user of this module still uses and almost
# only uses `services.prometheus.exporters.*.enable` to turn on the exporters,
# while all the other configurations are by default ready here.

{ config, lib, ... }: 

let prometheus = (import ../../data/service-registry.nix).prometheus;

in {
  config = {
    services.prometheus.exporters = {
      node = {
        inherit (prometheus.exporters.node) port;
        openFirewall = true;
        enabledCollectors = [
          "cpu"
          "systemd"
          "hwmon"
          "thermal_zone"
        ];
        disabledCollectors = [ "zfs" ];  # Use the standalone zfs exporter instead.
      };

      nvidia-gpu = {
        inherit (prometheus.exporters.nvidia-gpu) port;
        openFirewall = true;
      };
    };
  };
}
