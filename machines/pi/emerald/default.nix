{ config, pkgs, lib, ... }:

{
  imports = [
    ../common.nix
    ../../../base/build-machines.nix
  ];

  # +------------------------------+
  # | Hardware Related             |
  # +------------------------------+

  # TODO(breakds): fkms-3d cannot be enabled at 23.05 because of a bug:
  # https://github.com/NixOS/nixos-hardware/issues/631
  # Therefore, temporarily disable it.

  # Enable GPU acceleration
  # hardware.raspberry-pi."4".fkms-3d.enable = true;

  hardware.pulseaudio.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = "emerald";
    hostId = "f80a20bd";
    useDHCP = lib.mkDefault true;
  };

  # +------------------------------+
  # | Users                        |
  # +------------------------------+

  vital.mainUser = "breakds";

  # +------------------------------+
  # | Service and Package          |
  # +------------------------------+

  environment.systemPackages = with pkgs; [
    vim emacs git firefox
    dmidecode shuriken asciinema websocat
  ];

  vital.graphical = {
    enable = true;
    xserver.displayManager = "lightdm";
  };

  services.prometheus = {
    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" "cpu" "filesystem" ];
      port = 5821;
    };
  };

  # +--------------------+
  # | Distributed Build  |
  # +--------------------+

  vital.distributed-build = {
    enable = true;
    location = "homelab";
  };

  system.stateVersion = "23.11";
}
