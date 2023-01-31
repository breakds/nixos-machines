{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "lhh" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/lhh";
      uid = 1084;
	    description = "Xiaobo Liu";
      extraGroups = [];
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/lhh.pub
      ];
    };
  };
}