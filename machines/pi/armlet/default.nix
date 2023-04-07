{ config, pkgs, lib, ... }:

{
  imports = [
    ../common.nix
  ];

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

  vital.mainUser = "breakds";
  
  # +------------------------------+
  # | Service and Package          |
  # +------------------------------+
  
  environment.systemPackages = with pkgs; [
    vim emacs git firefox
    meld dmidecode shuriken asciinema websocat
    lsd
  ];

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "10.77.1.120";
        systems = [ "x86_64-linux" "i686-linux" ];
        maxJobs = 24;
        supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
      }
    ];
    settings = {
      trusted-substituters = [ "ssh://10.77.1.120" ];
    };
  };

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
  networking.firewall.allowedTCPPorts = [ 5821 ];

  system.stateVersion = "22.11"; 
}
