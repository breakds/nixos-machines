{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "dustin" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/dustin";
      uid = 1020;
	    description = "Dustin Miao";
      extraGroups = [
        "dustin"
      ];
    };
  };
}
