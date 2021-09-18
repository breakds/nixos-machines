{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "linxiao" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/linxiao";
      uid = 1081;
	    description = "Xiao Lin";
      extraGroups = [
        "linxiao"
	      "networkmanager"
	      "audio"
	      "plugdev"  # Allow members to mount/umount removable devices via pmount.
      ];
    };
  };
}
