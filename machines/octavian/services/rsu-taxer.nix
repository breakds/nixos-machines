{ config, pkgs, lib, ... }:

let rsu-taxer-info = (import ../../../data/service-registry.nix).rsu-taxer;


in {
  systemd.services.rsu-taxer = {
    description = "RSU Taxer";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [];

    serviceConfig = {
      ExecStart = "${pkgs.python3Packages.rsu-taxer}/bin/analyzer";
      Type = "simple";
      User = "root";
      Group = "root";
      Restart= "on-failure";
      RestartSec = "60s";
    };

    environment = {
      PNL_SERVER_PORT = toString rsu-taxer-info.port;
    };
  };

  services.nginx = {
    virtualHosts = {
      "${rsu-taxer-info.domain}" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString rsu-taxer-info.port}";
        };
      };
    };
  };
}
