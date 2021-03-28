{ config, pkgs, ... }:

{
  imports = [
    ../base
  ];
  
  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/breakds_samaritan.pub
      ];
    };

    vital.graphical.enable = true;
  };
}
