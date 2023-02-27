{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    # 2080 Le Zhao
    "lezhao" = {
      isNormalUser = true;
	    home = "/home/lezhao";
      uid = 2080;
	    description = "Le Zhao";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/lezhao.pub
      ];
    };
  };
}
