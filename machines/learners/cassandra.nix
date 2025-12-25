{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "cassandra" = {
      isNormalUser = true;
      home = "/home/cassandra";
      uid = 1007;
	    description = "Cassandra Qi";
      extraGroups = [
        "cassandra"
	      "networkmanager"
	      "audio"
	      "plugdev"  # Allow members to mount/umount removable devices via pmount.
      ];
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/cassandra_zen.pub
      ];
    };
  };
}
