# Laptop specific configuration

{ config, lib, pkgs, ... }:

{
  config = {
    # Handle lids for laptops.
    services.logind = {
      # The following settings configures the following behavior for laptops
      # When the lid close event is detected,
      #   1. If the external power is on, do nothing
      #   2. If the laptop is docked (external dock or monitor or hub), do nothing
      #   3. Otherwise, it should go to suspend and then hibernate. However this action
      #      will be held off for 60 seconds to wait for the users to dock or plug
      #      external power.
      lidSwitch = "suspend-then-hibernate";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
      extraConfig = ''
        HoldoffTimeoutSec=60
      '';
    };

    # Suspend-to-RAM. This state, if supported, offers significant power savings
    # as everything in the system is put into a low-power state, except for
    # memory, which should be placed into the self-refresh mode to retain its
    # contents.
    boot.kernelParams = [ "mem_sleep_default=deep" ];

    # Enable touchpad support
    services.libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        disableWhileTyping = true;
        # one finger = left, two finger = right
        clickMethod = "clickfinger";
      };
    };
  };
}
