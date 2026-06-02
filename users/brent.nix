{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "brent" = {
      isNormalUser = true;
      home = "/home/brent";
      uid = 2082;
      description = "Brent Millare";
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/brent_1.pub
        ../data/keys/brent_2.pub
      ];
    };
  };
}
