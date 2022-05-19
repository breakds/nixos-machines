{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "jerry.bai" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/jerry.bai";
      uid = 1083;
	    description = "Jerry Bai";
      extraGroups = [
        "jerry.bai"
	      "networkmanager"
	      "audio"
      ];
    };
  };
}
