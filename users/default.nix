{ config, lib, pkgs, ... }:

{
  config.users.extraUsers = {
    # 1007 Cassandra Qi
    "cassandra" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/cassandra";
      uid = 1007;
	    description = "Cassandra Qi";
      extraGroups = [
        "cassandra"
	      "networkmanager"
	      "audio"
	      "plugdev"  # Allow members to mount/umount removable devices via pmount.
      ];
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/cassandra_zen.pub
      ];
    };


    # 1082 Hao Peng
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
        ../data/keys/haopeng.pub
      ];
    };

    # 1084 Xiaobo Liu
    "lhh" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
	    home = "/home/lhh";
      uid = 1084;
	    description = "Xiaobo Liu";
      extraGroups = [];
      openssh.authorizedKeys.keyFiles = [
        ../data/keys/lhh.pub
      ];
    };
    
  };
}
