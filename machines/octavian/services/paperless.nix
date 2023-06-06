{ config, lib, pkgs, ... }:

let info = (import ../../../data/service-registry.nix).paperless;

in {
  services.paperless = {
    enable = true;
    port = info.port;
    dataDir = "/var/lib/paperless/data";
    mediaDir = "/var/lib/paperless/media";
    extraConfig = {
      PAPERLESS_ADMIN_USER = "breakds";
    };
  };

  services.nginx.virtualHosts = {
    "${info.domain}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString info.port}";
      };
    };
  };
}
