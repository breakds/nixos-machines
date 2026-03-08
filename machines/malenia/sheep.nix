{ config, pkgs, lib, ... }:

{
  # Shared bridge for all sheep containers. Each container connects to
  # this bridge and can reach the host at 10.33.1.1.
  networking.bridges.br-sheep.interfaces = [];

  networking.interfaces.br-sheep.ipv4.addresses = [{
    address = "10.33.1.1";
    prefixLength = 24;
  }];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br-sheep" ];
    externalInterface = "eno1";
  };

  containers.sheep = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br-sheep";
    localAddress = "10.33.1.2/24";

    bindMounts.data = {
      hostPath = "/home/breakds/sheep-workspace/first";
      mountPoint = "/home/breakds/workspace";
      isReadOnly = false;
    };

    config = { ... }: {
      nixpkgs.pkgs = pkgs;
      system.stateVersion = "25.05";
      networking.nameservers = [ "10.77.1.1" ];

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };

      users.users.breakds = {
        isNormalUser = true;
        home = "/home/breakds";
        uid = 1000;
        openssh.authorizedKeys.keyFiles = [
          ../../data/keys/breakds_malenia.pub
        ];
      };

      environment.systemPackages = with pkgs; [
        claude-code-bin
      ];
    };
  };
}
