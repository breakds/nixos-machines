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

    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
