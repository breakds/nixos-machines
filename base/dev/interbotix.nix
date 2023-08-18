# original rule comes from
# https://github.com/Interbotix/interbotix_ros_core/blob/main/interbotix_ros_xseries/interbotix_xs_sdk/99-interbotix-udev.rules

{ config, pkgs, lib, ... }:

let interbotix-udev = pkgs.writeTextDir "etc/udev/rules.d/99-interbotix.rules" ''
      # U2D2 board (also sets latency timer to 1ms for faster communication)
      SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", ENV{ID_MM_DEVICE_IGNORE}="1", ATTR{device/latency_timer}="1", SYMLINK+="ttyDXL", MODE:="0666", GROUP:="plugdev"
    '';
in {
  config = {
    services.udev.packages = [ interbotix-udev ];
  };
}
