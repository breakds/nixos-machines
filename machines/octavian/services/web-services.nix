{ config, lib, pkgs, ... }:

{
  services.nginx = {
    virtualHosts = {
      "www.breakds.org" = {
        enableACME = true;
        forceSSL = true;
        root = pkgs.www-breakds-org;
      };

      "extorage.breakds.org" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          root = "/var/lib/extorage";
        };
      };

      "llm.breakds.org" = lib.mkIf config.services.open-webui.enable {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.open-webui.port}";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.open-webui.environment = {
    CORS_ALLOW_ORIGIN = "https://llm.breakds.org";
  };
}
