{ config, lib, ... }:

let registry = (import ../../../data/service-registry.nix).atuin;

in {
  config = {
    # Note: atuin needs postgresql service running.
    services.atuin = {
      inherit (registry) port;
      enable = true;
      openRegistration = true;
    };

    services.nginx.virtualHosts."${registry.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString registry.port}";
    };
  };
}
