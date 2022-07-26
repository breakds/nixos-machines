{ config, lib, pkgs, ... }:

let shioriPort = 5931;

in {
  # Note that the first time to the web interface, we can use the default user
  # and password to login:
  #
  # username: shiori
  # password: gopher
  services.shiori = {
    enable = true;
    port = shioriPort;
  };

  networking.firewall = {
    allowedTCPPorts = [ shioriPort ];
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

     "shiori.breakds.org" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString shioriPort}";
        };
      };
    };
  };
}
