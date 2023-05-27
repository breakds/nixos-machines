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
    { device = "/dev/disk/by-uuid/e1f8967e-d61e-4ab2-8f86-bc15883c6a60";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/CE57-4DCC";
      fsType = "vfat";
    };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/BDS_HOME";
    fsType = "ext4";
  };

  fileSystems."/var/lib/wonder/warehouse" =
    { device = "/dev/disk/by-label/WONDER_WAREHOUSE";
      fsType = "ext4";
      # Do not block booting if the disck is missing
      options = [ "auto" "nofail" ];
    };

  fileSystems."/home/breakds/dataset" =
    { device = "/dev/disk/by-label/BDS_DATASET";
      fsType = "ext4";
      # Do not block booting if the disck is missing
      options = [ "auto" "nofail" ];
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
