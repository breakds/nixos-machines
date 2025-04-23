{ config, pkgs, lib, ... }:

{
  services.temporal = {
    enable = true;
    host = "0.0.0.0";
    namespaces = [ "general-dev" "factorai-dev" "beancounting" ];
    openFirewall = true;
  };
}
