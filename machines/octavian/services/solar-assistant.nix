{ config, pkgs, lib, ... }:

let
  domain = "solar.breakds.net";

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
          proxyPass = "http://10.77.1.52";
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
