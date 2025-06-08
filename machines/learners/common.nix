{ config, pkgs, lib, ... }:

{
  imports = [
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
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
      remote-desktop.enable = false;
      xserver.dpi = 100;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.vscode.enable = true;

    # Hopefully this is effectively ulimit -n 65535
    security.pam.loginLimits = [{
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }];

    services.prometheus.exporters = {
      node.enable = true;
      nvidia-gpu.enable = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  };
}
