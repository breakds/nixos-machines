{ config, pkgs, lib, ... }:

let wan-online = pkgs.callPackage ./pkgs/wan-online {};

in {
  systemd.services.check-wan-oneline = {
    description = "Check wan is online periodically";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "simple";

    script = "${wan-online}/bin/wan-online eno1 /tmp/online_state.txt";
  };

  systemd.timers.check-wan-oneline = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnStartupSec = "10s";
      OnUnitActiveSec = "1s";
    };
  };
}
