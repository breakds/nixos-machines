{ config, pkgs, lib, ... }:

{
  services.terraria = {
    enable = true;
    port = 5970;
    autoCreatedWorldSize = "medium";
    messageOfTheDay = "Welcome to the Farm.";
  };

  networking.firewall.allowedTCPPorts = [ config.services.terraria.port ];

  users = {
    groups.terraria = {};
    users.terraria.group = "terraria";
  };
}
