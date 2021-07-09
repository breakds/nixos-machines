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

  networking.firewall.allowedTCPPorts = [ 7777 ];
}
