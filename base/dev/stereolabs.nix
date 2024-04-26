{ config, pkgs, lib, ... }:

# Rules for the stereolabs camera such as ZED Mini and ZED 2
let
  slabs-udev = pkgs.writeTextDir "etc/udev/rules.d/99-slabs.rules" ''
    # HIDAPI/libusb
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f681", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f781", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f881", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666"

    # HIDAPI/hidraw
    KERNEL=="hidraw*", ATTRS{busnum}=="1", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f681", MODE="0666"
    KERNEL=="hidraw*", ATTRS{busnum}=="1", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f781", MODE="0666"
    KERNEL=="hidraw*", ATTRS{busnum}=="1", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f881", MODE="0666"
    KERNEL=="hidraw*", ATTRS{busnum}=="1", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666"

    # blacklist for usb autosuspend
    # http://kernel.org/doc/Documentation/usb/power-management.txt
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f780", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f781", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f881", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0424", ATTRS{idProduct}=="2512", TEST=="power/control", ATTR{power/control}="on"

    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f780", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f781", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f881", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0424", ATTRS{idProduct}=="2512", TEST=="power/autosuspend", ATTR{power/autosuspend}="-1"

    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f780", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f781", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b03", ATTRS{idProduct}=="f881", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0424", ATTRS{idProduct}=="2512", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
  '';

in {
  config = {
    services.udev.packages = [ slabs-udev ];
  };
}
