{ config, pkgs, lib, ... }:

{
  imports = [
    ../common.nix
    ../../../base/build-machines.nix
  ];

  # +------------------------------+
  # | Hardware Related             |
  # +------------------------------+

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;
  
  services.pulseaudio.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = "armlet";
    hostId = "ecb44699";
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
    meld dmidecode shuriken asciinema websocat
    lsd
  ];

  vital.graphical = {
    enable = true;
    xserver.displayManager = "lightdm";
  };

  services.prometheus.exporters.node.enable = true;

  # +--------------------+
  # | Distributed Build  |
  # +--------------------+

  vital.distributed-build = {
    enable = true;
    location = "homelab";
  };
  
  system.stateVersion = "22.11"; 
}
