{ pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "grapple";

  # Bootstrap without SSH keys. Remove these overrides after setting up
  # GitHub access and /root/.ssh/nixbuilder_malenia.
  vital.coding-agent.enabledAgents = [ "pi" ];
  vital.coding-agent.shepherd.enable = false;
  vital.distributed-build.builders = lib.mkForce [ ];

  # Keep systemd-boot until Secure Boot keys are enrolled in a later stage.
  boot.loader.systemd-boot.enable = true;

  # There is no swap configured for hibernation.
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Caps Lock -> Control on the built-in AT keyboard, regardless of revision.
  # Adapted from horizon.zero (596a610), which matched revision eAB54.
  services.udev.extraHwdb = ''
    evdev:input:b0011v0001p0001e*
      KEYBOARD_KEY_3a=leftctrl
  '';

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
