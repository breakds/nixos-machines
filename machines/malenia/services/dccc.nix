{ config, ... }:

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
    # HTTPS, for the microphone: https://dccc.breakds.net:7400.
    useACMEHost = "dccc.breakds.net";
  };

  # As home.breakds.net on octavian: a Cloudflare DNS challenge, for a name
  # that points at malenia's LAN address (DNS only, not proxied).
  config.security.acme = {
    acceptTerms = true;
    defaults.email = "bds@breakds.org";
    certs."dccc.breakds.net" = {
      dnsProvider = "cloudflare";
      group = config.services.nginx.group;
      environmentFile = config.age.secrets.cloudflare-env.path;
    };
  };

  config.age.secrets.cloudflare-env.file = ../../../secrets/cloudflare-env.age;
}
