{ config, lib, pkgs, ... }:

{
  # +----------------+
  # | Overlays       |
  # +----------------+

  services.nginx.virtualHosts = {
    "lab.breakds.org" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:7777";
    };
  };
}
