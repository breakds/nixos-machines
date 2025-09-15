{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "toph" = {
      isNormalUser = true;
      home = "/home/toph";
      uid = 2084;
      description = "Chris Toph";
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/toph.pub
      ];
    };
  };
}
