{ config, pkgs, lib, ... }:

{
  services.temporal-dev-server = {
    enable = true;
    host = "0.0.0.0";
    namespaces = [
      "factorai-dev"
      "general-dev"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    config.services.temporal-dev-server.ports.api
    config.services.temporal-dev-server.ports.ui
  ];
}
