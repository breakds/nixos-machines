{ config, pkgs, lib, ... }:

let registry = (import ../../../data/service-registry.nix).glance;
    port = config.services.glance.settings.server.port;

in {
  services.glance.enable = true;

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
          proxyPass = "http://localhost:${toString port}";
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
