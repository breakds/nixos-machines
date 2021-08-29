{ config, lib, pkgs, ... }:

{
  services.nginx = {
    virtualHosts = {
      "www.breakds.org" = {
        enableACME = true;
        forceSSL = true;
        root = pkgs.www-breakds-org;
      };
    };
  };
}
