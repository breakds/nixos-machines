{ config, pkgs, lib, ... }:

{
  config = {
    # Need the service running
    services.expressvpn.enable = true;

    # Also need the command line tool for interacting such as activate and connect
    environment.systemPackages = with pkgs; [
      expressvpn
    ];
  };
}
