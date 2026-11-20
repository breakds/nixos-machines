{ ... }:

let info = (import ../../../data/service-registry.nix).dccc;

in {
  # The one public route to dccc: the Index 01 ring's webhook, which the
  # Pebble app on the phone sends from anywhere. It goes over the home LAN to
  # malenia's webhook origin, which serves only POST /decree, and dccc-decree
  # refuses any request without the app's signature. dccc itself stays on the
  # home network.
  #
  # The rate is per client address; behind a Cloudflare proxy that would be
  # Cloudflare's, so keep decree.breakds.org DNS only.
  services.nginx.appendHttpConfig = ''
    limit_req_zone $binary_remote_addr zone=dccc_decree:1m rate=30r/m;
  '';

  services.nginx.virtualHosts.${info.decreeDomain} = {
    enableACME = true;
    forceSSL = true;
    locations."/".return = "404";
    locations."~ ^/decree(/[^/]+)?$" = {
      proxyPass = "https://dccc.breakds.net:${toString info.ports.webhook}";
      extraConfig = ''
        limit_except POST { deny all; }
        # A burst for the backlog the app retries when the phone is online again.
        limit_req zone=dccc_decree burst=20 nodelay;
        # As much as dccc-decree takes; 5 minutes of the ring's audio is ~2 MB.
        client_max_body_size 8m;
        # malenia's certificate is for dccc.breakds.net, a LAN address.
        proxy_ssl_server_name on;
        proxy_ssl_name dccc.breakds.net;
        proxy_ssl_verify on;
        proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
      '';
    };
  };
}
