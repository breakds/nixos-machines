# This plugs the udev rules for the Sagittarius K1 robotic arm. The
# original rule comes from
# https://github.com/NXROBO/sagittarius_arm_ros/blob/main/sdk_sagittarius_arm/rules/sagittarius-usb-serial.rules

{ config, pkgs, lib, ... }:

let sagittarius-udev = pkgs.writeTextDir "etc/udev/rules.d/98-sagittarius-serial.rules" ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2e88", ATTRS{idProduct}=="4603", SYMLINK+="sagittarius", MODE:="0666", GROUP:="plugdev"
    '';
in {
  config = {
    services.udev.packages = [ sagittarius-udev ];
  };
}
