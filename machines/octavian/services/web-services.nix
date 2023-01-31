{ config, lib, pkgs, ... }:

let shioriInfo = (import ../../../data/service-registry.nix).shiori;

in {
  # Note that the first time to the web interface, we can use the default user
  # and password to login:
  #
  # username: shiori
  # password: gopher
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
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
