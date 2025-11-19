{ config, lib, pkgs, ... }:

{
  boot.isContainer = true;
  services.openssh = {
    enable = lib.mkDefault true;
    settings.passwordAuthentication = false;
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
      ../data/keys/breakds_malenia.pub      
    ];
  };

  # Allow the user "operator" to sudo without typing password
  security.sudo.extraRules = [
    {
      users = [ "operator" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ];} ];
    }
  ];
}
