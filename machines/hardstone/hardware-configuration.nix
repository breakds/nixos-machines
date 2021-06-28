# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/c71cbcab-4e28-4dbe-bd1e-308f9d22f6b0";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4BE4-0BC3";
      fsType = "vfat";
    };

  fileSystems."/var/lib/chia/plotting/nvme1" =
    { device = "/dev/disk/by-label/CHIAPLOT1";
      fsType = "ext4";
    };

  fileSystems."/var/lib/chia/plotting/nvme2" =
    { device = "/dev/disk/by-label/CHIAPLOT2";
      fsType = "ext4";
    };

  fileSystems."/var/lib/chia/farm/CHIAFARM5" =
    { device = "/dev/disk/by-label/CHIAFARM5";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F30" =
    { device = "/dev/disk/by-label/F30";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F31" =
    { device = "/dev/disk/by-label/F31";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F32" =
    { device = "/dev/disk/by-label/F32";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F33" =
    { device = "/dev/disk/by-label/F33";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };


  # iSCSI devices
  
  fileSystems."/var/lib/chia/farm/F01" =
    { device = "/dev/disk/by-label/F01";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F04" =
    { device = "/dev/disk/by-label/F04";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F07" =
    { device = "/dev/disk/by-label/F07";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/F22" =
    { device = "/dev/disk/by-label/F22";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  fileSystems."/var/lib/chia/farm/CHIAFAMR4" =
    { device = "/dev/disk/by-label/CHIAFARM4";
      fsType = "ext4";
      options = [ "auto" "nofail" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/2ca4fc6a-7643-4a77-af7f-14a57011ab23"; }
    ];

  nix.maxJobs = lib.mkDefault 16;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}