{ config, ... }:

{
  # Peer and folder settings live in the private nixos-home repository.
  home-manager.users.${config.vital.mainUser}.services.syncthing.enable = true;

  users.users.${config.vital.mainUser}.linger = true;

  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 21027 22000 ];
  };
}
