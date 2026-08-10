{ config, pkgs, lib, ... }:

let
  domain = "solar.breakds.net";
  registry = (import ../../../data/service-registry.nix).solar-assistant;

  # The solar assistant appliance on the home VLAN. It has no
  # authentication of its own.
  upstream = "http://10.77.1.52";

in {
  security.acme.certs = {
    "${domain}" = {
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
      "${domain}" = {
        addSSL = true;
        # NOTE: Instead of `enableACME`, this directly refer the certificate in
        # `security.acme.certs`. This is because the domain here is only used
        # locally.
        useACMEHost = "${domain}";
        locations."/" = {
          proxyPass = upstream;
          proxyWebsockets = true;
          extraConfig = ''
            allow 10.77.1.0/24;
            deny all;
          '';
        };
      };

      # Internet-facing exposure. The appliance itself is wide open, so the
      # vhost sits behind the kanidm gate (see gate.nix): registering it in
      # oauth2-proxy.nginx.virtualHosts below makes nginx check every
      # request against oauth2-proxy and bounce strangers to the login flow.
      "${registry.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = upstream;
          proxyWebsockets = true;
        };
      };
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."${registry.domain}" = { };
}
