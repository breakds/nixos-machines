{ ... }:

let ports = (import ../../../data/service-registry.nix).dccc.ports;

in {
  # Enabled for breakds by inputs.dccc.nixosModules.malenia.
  config.services.dccc = {
    appPort = ports.app;
    pagesPort = ports.pages;
    runtimePort = ports.runtime;
    gatewayPort = ports.gateway;
  };
}
