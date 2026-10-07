# Bluetooth hardening for the Intel AX210 combo card (Wi-Fi 6E + BT 5.4),
# which exposes the BT controller over USB (8087:0032).
#
# With USB autosuspend enabled (default: 2 s idle), the controller wakes
# up late after the keyboard/mouse go quiet, which surfaces as random
# disconnects of paired devices. This file keeps the USB device awake.
{ config, lib, pkgs, ... }:

{
  # The udev rule covers (re)enumeration events, but on this machine the
  # very early boot-time event races the attribute write (the device
  # stays at power/control=auto), so a small oneshot service guarantees
  # the state after boot.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="8087", \
      ENV{ID_MODEL_ID}=="0032", ATTR{power/control}="on"
  '';

  systemd.services.intel-bt-keep-awake = {
    description =
      "Keep the Intel AX210 Bluetooth USB device awake (disable USB autosuspend)";
    wantedBy = [ "multi-user.target" ];
    script = ''
      for d in /sys/bus/usb/devices/*; do
        [ "$(cat "$d/idVendor" 2>/dev/null)" = "8087" ] || continue
        [ "$(cat "$d/idProduct" 2>/dev/null)" = "0032" ] || continue
        echo on > "$d/power/control"
        exit 0
      done
      exit 1
    '';
  };

  # Diagnostics: check wlp1s0 band/link (2.4 GHz Wi-Fi coexists badly
  # with BT on the AX210).
  environment.systemPackages = [ pkgs.iw ];
}
