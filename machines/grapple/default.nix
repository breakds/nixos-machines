{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "grapple";

  # Keep systemd-boot until Secure Boot keys are enrolled in a later stage.
  boot.loader.systemd-boot.enable = true;

  # There is no swap configured for hibernation.
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # The shared Niri config includes this file. Leave output mode and scale automatic.
  home-manager.users.breakds.xdg.configFile."niri/local.kdl".text = ''
    layout {
        gaps 12
    }
    environment {
        GTK_IM_MODULE null
        QT_IM_MODULE null
    }
  '';

  # Keep the versions from the original installation, even when upgrading NixOS.
  system.stateVersion = "25.11";
  home-manager.users.breakds.home.stateVersion = "25.11";
}
