{ config, lib, pkgs, ... }:
  
{
  config = {
    services.tailscale = {
      enable = true;
      port = 41661;  # The default is 41641.
    };

    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
    networking.firewall.checkReversePath = "loose";

    environment.systemPackages = with pkgs; [ tailscale ];
  };
}
