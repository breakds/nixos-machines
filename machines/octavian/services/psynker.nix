{ config, lib, pkgs, ... }:

{
  services.nginx.virtualHosts."cradle.psynk.ai" = {
    enableACME = true;
    forceSSL = true;

    locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$" = {
      proxyPass = "http://10.77.1.56:9120";
      recommendedProxySettings = true;
      # KEPT: This is for long-term browser caching of static files.
      extraConfig = ''
        add_header "Cache-Control" "public, immutable, max-age=31536000";
      '';
    };

    locations."/" = {
      proxyPass = "http://10.77.1.56:9120";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        add_header "Cache-Control" "no-cache, no-store, must-revalidate";
      '';
    };
  };
}
