{ config, ... }:

{
  config = {
    services.shepherd-fleet = {
      enable = true;
      keyFiles = [ ../../../data/keys/breakds_malenia.pub ];
      port = (import ../../../data/service-registry.nix).shepherd.port;
      openFirewall = true;
    };
  };
}
