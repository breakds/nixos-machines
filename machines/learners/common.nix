{ config, pkgs, ... }:

{
  imports = [
    ../../base
    ../../base/build-machines.nix
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../base/traintrack/agent.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      xserver.dpi = 100;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;
    vital.programs.vscode.enable = true;
    vital.programs.machine-learning.enable = true;

    services.prometheus = {
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" "cpu" "filesystem" ];
        port = 5821;
      };
    };
    networking.firewall.allowedTCPPorts = [ 5821 ];
  };
}
