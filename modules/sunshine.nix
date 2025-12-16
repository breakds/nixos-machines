{ config, pkgs, lib, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;  # Port 47974 - 47990, TCP + UDP
  };

  # Enable uinput for mouse/keyboard emulation
  # Without this, you can see the screen but your Vision Pro input won't work.  
  # boot.kernelModules = [ "uinput" ];
  # services.udev.extraRules = ''
  #   KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
  # '';
}
