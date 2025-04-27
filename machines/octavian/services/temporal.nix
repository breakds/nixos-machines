{ config, pkgs, lib, ... }:

let registry = (import ../../../data/service-registry.nix).temporal;

in {
  services.temporal = {
    enable = true;
    host = "0.0.0.0";
    namespaces = [ "general-dev" "factorai-dev" "beancounting" ];
    openFirewall = true;
    allowInsecureCookie = true;
  };

  services.nginx = {
    virtualHosts = {
      "${registry.domain}" = {
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
