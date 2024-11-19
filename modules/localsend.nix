# Airdrop alternative in local network

{ config, lib, pkgs, ... }:

let port = (import ../data/service-registry.nix).localsend.port;

in {
  environment.systemPackages = with pkgs; [
    localsend
  ];

  networking.firewall.allowedUDPPorts = [ port ];
  networking.firewall.allowedTCPPorts = [ port ];
}
