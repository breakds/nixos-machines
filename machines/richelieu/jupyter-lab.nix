{ config, lib, pkgs, ... }:

{
  # +----------------+
  # | Overlays       |
  # +----------------+

  services.nginx.virtualHosts = {
    "lab.breakds.org" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/".proxyPass = "http://localhost:7777";
        "~ /api/kernels/" = {
          proxyPass = "http://localhost:7777";
          extraConfig = ''
            proxy_http_version    1.1;
            proxy_set_header      Upgrade "websocket";
            proxy_set_header      Connection "Upgrade";
            proxy_read_timeout    86400;
          '';
        };
        "~ /terminals/" = {
          proxyPass = "http://localhost:7777";
          extraConfig = ''
            proxy_http_version    1.1;
            proxy_set_header      Upgrade "websocket";
            proxy_set_header      Connection "Upgrade";
            proxy_read_timeout    86400;
          '';
        };
      };
    };
  };
}
