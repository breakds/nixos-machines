{ ... }:

let ports = (import ../../../data/service-registry.nix).dccc.ports;

in {
  # Enabled for breakds by inputs.dccc.nixosModules.malenia.
  config.services.dccc = {
    # Reachable from the home network. dccc has no login.
    listenAddress = "0.0.0.0";
    openFirewall = true;
    appPort = ports.app;
    pagesPort = ports.pages;
    runtimePort = ports.runtime;
    gatewayPort = ports.gateway;
  };
}
