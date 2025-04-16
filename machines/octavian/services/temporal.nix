{ config, pkgs, lib, ... }:

{
  services.temporal = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [
    config.services.temporal.ports.api
    config.services.temporal.ports.ui
  ];
}
