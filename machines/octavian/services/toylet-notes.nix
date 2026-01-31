{ config, pkgs, lib, ... }:

let registry = (import ../../../data/service-registry.nix).toylet-notes;

in {
  services.toylet-note = {
    enable = true;
    port = registry.port;
    domainName = registry.domain;
  };
}
