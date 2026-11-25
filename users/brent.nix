{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    "brent" = {
      isNormalUser = true;
      home = "/home/brent";
      uid = 2082;
      description = "Brent Millare";
    };
  };
}
