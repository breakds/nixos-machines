{ config, lib, pkgs, ... }:

{
  # +----------------+
  # | Overlays       |
  # +----------------+

  nixpkgs.overlays = [
    (final: prev: {
      www-breakds-org = final.callPackage ../../pkgs/www-breakds-org {};
    })
  ];
  
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
