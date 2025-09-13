{ config, lib, pkgs, ... }:

{
  # 1. qmk setup qmk/qmk_firmware -H $HOME/projects/qmk/qmk_firmware
  # 2. qmk cd     # This starts the nix-shell I think
  # 3. Copy keyboards/geonix40/ from your vendor package into qmk_firmware/keyboards/
  config = {
    services.udev.packages = [ pkgs.qmk-udev-rules ];
    environment.systemPackages = with pkgs; [
      dfu-util qmk
    ];
  };
}
