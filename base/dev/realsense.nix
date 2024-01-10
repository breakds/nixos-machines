{ config, pkgs, lib, ... }:

# The following-rules basically makes sure that the user can access the real
# sense camera without sudo. They are copied from the udev rules that come with
# librealsense. Some unnecessary rules are removed.
#
# TODO(breakds): Too many rules. We should add option to support selected models only.
let realsense-udev = pkgs.writeTextDir "etc/udev/rules.d/98-realsense-libusb.rules" ''
      ##Version=1.1##
      # Device rules for Intel RealSense devices (R200, F200, SR300 LR200, ZR300, D400, L500, T200)
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0a80", MODE:="0666", GROUP:="plugdev", RUN+="/usr/local/bin/usb-R200-in_udev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0a66", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0aa3", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0aa2", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0aa5", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0abf", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0acb", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad0", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="04b4", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad1", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad2", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad3", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad4", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad5", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad6", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0af2", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0af6", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0afe", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0aff", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b00", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b01", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b03", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b07", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b0c", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b0d", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3d", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b48", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b49", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b4b", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b4d", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b52", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5c", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b64", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b68", MODE:="0666", GROUP:="plugdev"

      # Intel RealSense recovery devices (DFU)
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ab3", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adb", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adc", MODE:="0666", GROUP:="plugdev"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b55", MODE:="0666", GROUP:="plugdev"

      # Intel RealSense devices (Movidius, T265)
      SUBSYSTEMS=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="8087", ATTRS{idProduct}=="0af3", MODE="0666", GROUP="plugdev"
      SUBSYSTEMS=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="8087", ATTRS{idProduct}=="0b37", MODE="0666", GROUP="plugdev"
      SUBSYSTEMS=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="03e7", ATTRS{idProduct}=="2150", MODE="0666", GROUP="plugdev"

      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad5", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor_custom", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad5", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0af2", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0af2", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0afe", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor_custom", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0afe", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0aff", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor_custom", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0aff", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b00", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor_custom", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b00", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b01", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor_custom", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b01", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3d", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3d", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b4b", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b4b", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b4d", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b4d", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5c", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5c", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b64", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b64", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b68", MODE:="0777", GROUP:="plugdev", RUN+="/bin/sh -c 'chmod -R 0777 /sys/%p'"
      DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b68", RUN+="/bin/sh -c ' chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"

      # For products with motion_module, if (kernels is 4.15 and up) and (device name is "accel_3d") wait, in another process, until (enable flag is set to 1 or 200 mSec passed) and then set it to 0.
      KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ad5|0afe|0aff|0b00|0b01|0b3a|0b3d|0b64|0b68", RUN+="/bin/sh -c '(major=`uname -r | cut -d \".\" -f1` && minor=`uname -r | cut -d \".\" -f2` && (([ $major -eq 4 ] && [ $minor -ge 15 ]) || [ $major -ge 5 ])) && (enamefile=/sys/%p/name && [ `cat $enamefile` = \"accel_3d\" ]) && enfile=/sys/%p/buffer/enable && echo \"COUNTER=0; while [ \$COUNTER -lt 20 ] && grep -q 0 $enfile; do sleep 0.01; COUNTER=\$((COUNTER+1)); done && echo 0 > $enfile\" | at now'"
      '';

in {
  config = {
    services.udev.packages = [ realsense-udev ];
  };
}
