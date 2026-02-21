{ config, pkgs, lib, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;  # Port 47974 - 47990, TCP + UDP
  };
}
