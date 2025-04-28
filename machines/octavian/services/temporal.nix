{ config, pkgs, lib, ... }:

let registry = (import ../../../data/service-registry.nix).temporal;

in {
  services.temporal = {
    enable = true;
    host = "0.0.0.0";
    namespaces = [ "general-dev" "factorai-dev" "beancounting" ];
  };

  security.acme.certs = {
    "${registry.domain}" = {
      dnsProvider = "cloudflare";
      group = config.services.nginx.group;
      # What is in the files?
      #
      # CLOUDFLARE_EMAIL=...
      # CLOUDFLARE_API_KEY=... 
      environmentFile = "/home/breakds/certs/cloudflare.env";
    };
  };

  services.nginx = {
    virtualHosts = {
      "${registry.domain}" = {
        addSSL = true;
        # NOTE: Instead of `enableACME`, this directly refer the certificate in
        # `security.acme.certs`. This is because the domain here is only used
        # locally.
        useACMEHost = "${registry.domain}";
        locations."/" = {
          proxyPass = "http://localhost:${toString registry.ports.ui}";
          proxyWebsockets = true;
          extraConfig = ''
          allow 10.77.1.0/24;
          deny all;
        '';
        };
      };
    };
  };
}
