{ config, lib, pkgs, ... }:

{
  boot.isContainer = true;
  services.openssh = {
    enable = lib.mkDefault true;
    passwordAuthentication = false;
  };

  users.extraUsers.operator = {
    isNormalUser = true;
    home = "/home/operator";
    uid = 1000;
    description = "The opereator of the container";
    extraGroups = [
      "operator"
      "wheel"
      "networkmanager"
      "nginx"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../data/keys/breakds_samaritan.pub
    ];
  };
}
