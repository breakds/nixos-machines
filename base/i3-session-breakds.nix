{ config, pkgs, lib, ... }:

let windowManager = config.home-manager.users."breakds".home.bds.windowManager;

in {
  services.xserver.desktopManager.session = lib.optionals (windowManager == "i3") [
    {
      name = "home-manager";
      start = ''
        ${pkgs.runtimeShell} $HOME/.hm-xsession &
        waitPID=$!
      '';
    }
  ];

  # Otherwise swaylock won't work
  security.pam.services.swaylock = lib.mkIf (windowManager == "sway") {
    # Do not activate finger print for swaylock
    fprintAuth = false;
  };

  services.displayManager = {
    sessionPackages = lib.optionals (windowManager == "sway") [ pkgs.sway ];
  };
}
