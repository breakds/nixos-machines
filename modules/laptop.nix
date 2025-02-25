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

    # Enable powertop's auto tuning. This runs at startup and makes your battery
    # life happy.
    powerManagement.powertop.enable = true;

    services.thermald.enable = true;

    services.power-profiles-daemon.enable = false;  # Turn off, conflict with tlp.
    services.tlp = {
      enable = true;
      settings = { # sudo tlp-stat or tlp-stat -s or sudo tlp-stat -p
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 81;
      };
    };
  };
}
