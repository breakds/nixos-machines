{ config, lib, pkgs, ... }:

{
  services.nginx = {
    virtualHosts = {
      "10.77.1.130" = {
        enableACME = true;
        forceSSL = true;
        root = pkgs.www-breakds-org;
      };
    };
  };
}
