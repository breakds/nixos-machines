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
}
