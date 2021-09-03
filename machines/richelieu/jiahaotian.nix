{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "jiahaotian" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/jiahaotian";
      uid = 1080;
	    description = "Haotian Jia";
      extraGroups = [
        "jiahaotian"
	      "networkmanager"
	      "audio"
	      "plugdev"  # Allow members to mount/umount removable devices via pmount.
      ];
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/jiahaotian_key.pub
      ];
    };
  };
}
