{ config, lib, pkgs, ... }:

{
  config = {
    users.extraUsers.cassandra = {
      isNormalUser = true;
	    home = "/home/cassandra";
      uid = 1001;
	    description = "Cassandra Qi";
      extraGroups = [
	      "cassandra"
	      "wheel"  # For sudo
	      "networkmanager"
	      "dialout"  # Access /dev/ttyUSB* devices
	      "uucp"  # Access /ev/ttyS... RS-232 serial ports and devices.
	      "audio"
	      "plugdev"  # Allow members to mount/umount removable devices via pmount.
	      "docker"
        "samba"
      ];
    };
  };
}
