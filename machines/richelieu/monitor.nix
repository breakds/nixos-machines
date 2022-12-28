{ config, lib, ... }:

{
  services.grafana = {
    enable = true;
    addr = "127.0.0.1";
    domain = "grafana.breakds.org";
    port = 5810;
  };

  services.nginx = {
    virtualHosts = {
      "${config.services.grafana.domain}" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "https://localhost:${toString config.services.grafana.port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
