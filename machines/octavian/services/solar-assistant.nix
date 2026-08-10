{ config, pkgs, lib, ... }:

let
  registry = (import ../../../data/service-registry.nix).solar-assistant;

  # The solar assistant appliance on the home VLAN. It has no
  # authentication of its own.
  upstream = "http://10.77.1.52";

in {
  # The appliance itself is wide open, so the vhost sits behind the kanidm
  # gate (see gate.nix): registering it in oauth2-proxy.nginx.virtualHosts
  # below makes nginx check every request against oauth2-proxy and bounce
  # strangers to the login flow.
  services.nginx.virtualHosts."${registry.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = upstream;
      proxyWebsockets = true;
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."${registry.domain}" = { };
}
