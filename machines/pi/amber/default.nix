{ config, pkgs, lib, ... }:

{
  imports = [
    ../common.nix
    ../../../base/build-machines-v2.nix
  ];

  # +------------------------------+
  # | Hardware Related             |
  # +------------------------------+

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = "amber";
    hostId = "918a9607";
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
    caches = [ "octavian" ];
    builders = [ "octavian" "malenia" ];
  };
  
  system.stateVersion = "23.11"; 
}
