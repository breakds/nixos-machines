{ config, lib, pkgs, ... }:

let
  kernelVersion = config.boot.kernelPackages.kernel.version;

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

in {
  boot.kernelPackages = lib.mkOverride 1100 pkgs.linuxPackages_latest;

  assertions = [{
    assertion = copyFailIsFixed;
    message =
      "vital-base requires a kernel new enough for CVE-2026-31431 / Copy Fail.";
  } {
    assertion =
      lib.versionAtLeast kernelVersion "7.3"
      || (lib.versionAtLeast kernelVersion "7.2.10"
        && lib.versionOlder kernelVersion "7.3")
      || (lib.versionAtLeast kernelVersion "6.18.56"
        && lib.versionOlder kernelVersion "6.19")
      || (lib.versionAtLeast kernelVersion "6.12.113"
        && lib.versionOlder kernelVersion "6.13");
    message = "vital-base requires a kernel fixed for CVE-2026-98432.";
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
