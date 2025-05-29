{ config, pkgs, lib, ... }:

{
  config = {
    services.redis.servers = {
      voyage = {
        enable = true;
        user = "cassandra";
        group = "users";
        port = 6379;
      };
    };

    # So that the voyager backend runs at 5000 and can be exposed.
    networking.firewall.allowedUDPPorts = [ 5000 ];
    networking.firewall.allowedTCPPorts = [ 5000 ];
  };
}
