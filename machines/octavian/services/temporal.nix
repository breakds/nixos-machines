{ config, pkgs, lib, ... }:

{
  services.temporal = {
    enable = true;
    host = "0.0.0.0";
    domains = [
      "http://localhost:${toString config.services.temporal.ports.ui}"
      "http://octavian.local:${toString config.services.temporal.ports.ui}"
    ];
    namespaces = [ "general-dev" "factorai-dev" "beancounting" ];
    openFirewall = true;
  };
}
