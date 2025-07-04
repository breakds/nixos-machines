{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    # 2081 Le Zhao
    "lx" = {
      isNormalUser = true;
	    home = "/home/lx";
      uid = 2081;
	    description = "Xin Li";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/lx.pub
      ];
    };
  };
}
