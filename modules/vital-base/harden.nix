{ config, lib, pkgs, ... }:

let
  kernelVersion = config.boot.kernelPackages.kernel.version;
  hasZfs = config.boot.supportedFilesystems ? zfs;

  # Copy Fail is fixed in mainline 7.0+, plus stable backports including
  # 6.19.12+, 6.18.22+, and the 6.12 LTS line currently in nixpkgs.
  copyFailIsFixed =
    lib.versionAtLeast kernelVersion "7.0"
    || (lib.versionAtLeast kernelVersion "6.19.12"
      && lib.versionOlder kernelVersion "6.20")
    || (lib.versionAtLeast kernelVersion "6.18.22"
      && lib.versionOlder kernelVersion "6.19")
    || (lib.versionAtLeast kernelVersion "6.12.84"
      && lib.versionOlder kernelVersion "6.13");

  # ZFS 2.3.6 is marked broken against Linux 7.0.2 in current nixpkgs.
  # Keep ZFS hosts on patched LTS while newer laptop hardware can still use
  # the latest kernel selected by nixos-hardware.
  patchedKernelPackages =
    if hasZfs then pkgs.linuxPackages_6_12 else pkgs.linuxPackages_latest;

in {
  boot.kernelPackages = lib.mkOverride 1100 patchedKernelPackages;

  assertions = [{
    assertion = copyFailIsFixed;
    message =
      "vital-base requires a kernel new enough for CVE-2026-31431 / Copy Fail.";
  }];

  # Emergency mitigation reference for CVE-2026-31431 / Copy Fail:
  #
  # boot.blacklistedKernelModules = [
  #   "algif_aead"
  #   "authencesn"
  # ];
  #
  # boot.extraModprobeConfig = ''
  #   install algif_aead ${pkgs.coreutils}/bin/false
  #   install authencesn ${pkgs.coreutils}/bin/false
  # '';
  #
  # boot.kernelParams = [
  #   "initcall_blacklist=algif_aead_init"
  # ];
}
