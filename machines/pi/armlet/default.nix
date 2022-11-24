{ config, pkgs, lib, ... }:

{

  # +------------------------------+
  # | Hardware Related             |
  # +------------------------------+    

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  hardware.pulseaudio.enable = true;

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

  users = {
    extraUsers."breakds" = {
      isNormalUser = true;
      initialHashedPassword = lib.mkDefault "$5$o2c1SrFVg1xK570h$EO3uklJz1y3SbIPJ5zBUdG6ZYNFKoui3EYa5CX/9j0A";
      home = "/home/breakds";
      extraGroups = [ "wheel" "neteworkmanager" "audio" "plugdev" ];
      openssh.authorizedKeys.keyFiles = [
        ../../../data/keys/breakds_samaritan.pub
      ];
    };
  };

  # +------------------------------+
  # | Service and Package          |
  # +------------------------------+
  
  environment.systemPackages = with pkgs; [ vim emacs git firefox ];

  services.openssh.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
    desktopManager.gnome.enable = true;
  };

  system.stateVersion = "22.11"; 
}
