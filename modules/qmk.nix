{ config, lib, pkgs, ... }:

{
  config = {
    services.udev.packages = [ pkgs.qmk-udev-rules ];
    environment.systemPackages = with pkgs; [
      dfu-util qmk
    ];
  };
}
