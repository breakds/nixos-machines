{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "hao" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/hao";
      uid = 1082;
	    description = "Hao Peng";
      extraGroups = [
        "hao"
	      "audio"
        "docker"
	      "plugdev"  # Allow members to mount/umount removable devices via pmount.
      ];
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/haopeng.pub
      ];
    };
  };
}
