{ config, lib, ... }:

let info = (import ../../../data/service-registry.nix).docker-registry;

in {
  services.dockerRegistry = {
    enable = true;
    # Do not enable redis cache for simplicity.
    enableRedisCache = false;
    enableGarbageCollect = true;
    port = info.port;
  };

  networking.firewall.allowedTCPPorts = [ info.port ];

  services.nginx.virtualHosts = lib.mkIf config.services.nginx.enable {
    "${info.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString info.port}";

      extraConfig = ''
        client_max_body_size 20G;
      '';
    };
  };
}
