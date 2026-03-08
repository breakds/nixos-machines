{ config, pkgs, lib, ... }:

{
  containers.sheep = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.33.1.1";
    localAddress = "10.33.1.2";

    bindMounts.data = {
      hostPath = "/home/breakds/sheep-workspace/first";
      mountPoint = "/home/breakds/workspace";
      isReadOnly = false;
    };

    config = { pkgs, ... }: {
      system.stateVersion = "25.05";

      services.openssh = {
        enable = true;
        settings.passwordAuthentication = false;
      };

      users.users.breakds = {
        isNormalUser = true;
        home = "/home/breakds";
        uid = 1000;
        openssh.authorizedKeys.keys = [
          ../../data/keys/breakds_malenia.pub
        ];
      };

      environment.systemPackages = with pkgs; [
        claude-code-bin
      ];
    };
  };
}
