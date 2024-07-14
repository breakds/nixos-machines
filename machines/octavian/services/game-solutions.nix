{ config, pkgs, lib, ... }:

let kiseki-info = (import ../../../data/service-registry.nix).kiseki;


in {
  systemd.services.kiseki = {
    description = "Tools for the kiseki game series";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [];

    serviceConfig = {
      ExecStart = "${pkgs.kiseki}/bin/kiseki-backend";
      Type = "simple";
      User = "root";
      Group = "root";
      Restart= "on-failure";
      RestartSec = "60s";
    };

    environment = {
      KISEKI_BACKEND_PORT = toString kiseki-info.port;
    };
  };

  services.nginx = {
    virtualHosts = {
      "${kiseki-info.domain}" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString kiseki-info.port}";
        };
      };
    };
  };
}
