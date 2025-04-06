{ config, lib, pkgs, ... }:

let info = (import ../../../data/service-registry.nix).n8n;

in {
  config = {
    services.n8n = {
      enable = true;
      settings = {
        port = info.port;
        generic.timezone = "America/Los_Angeles";
        diagnostics.enable = false;
        versionNotifications.enable = false;
      };
    };
  };
}
