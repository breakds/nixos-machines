{ config, ... }:

{
  config = {
    services.shepherd-fleet = {
      enable = true;
      port = (import ../../../data/service-registry.nix).shepherd.port;
      openFirewall = true;
    };
  };
}
