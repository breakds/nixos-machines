{ config, lib, pkgs, ... }:

{
  services.nginx.virtualHosts."cradle.psynk.ai" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.77.1.56:9119";
      proxyWebsockets = true;
    };
  };
}
