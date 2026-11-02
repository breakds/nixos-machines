{ config, pkgs, lib, ... }:

let registry = (import ../../../data/service-registry.nix).toylet-notes;

in {
  # The locked Reading Desk frontend uses pnpm 10 only for its offline,
  # sandboxed build; pnpm is absent at runtime. Remove after it moves to 11.
  vital.insecurePackages = [ "pnpm-10.34.0" ];

  services.toylet-notes = {
    enable = true;
    port = registry.port;
    domainName = registry.domain;
  };
}
