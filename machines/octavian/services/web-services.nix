{ config, lib, pkgs, ... }:

let shioriInfo = (import ../../../data/service-registry.nix).shiori;

in {
  # Note that the first time to the web interface, we can use the default user
  # and password to login:
  #
  # username: shiori
  # password: gopher
  #
  # Migration of shiori is simple, just copy its state directory under
  # /var/lib/shiori (note that this might be a symbolic link to
  # /var/lib/private/shiori).
  services.shiori = {
    enable = true;
    port = shioriInfo.port;
  };
  
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

      "${shioriInfo.domain}" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString shioriInfo.port}";
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
