{ config, lib, pkgs, ... }:

let
  # Copy Fail is fixed in Linux 6.19.12+, 6.18.22+, and 7.0+.
  # The stock 6.19 kernel is EOL in current nixpkgs, so use the latest
  # maintained kernel package set instead of pinning an unavailable 6.19.14.
  patchedKernelPackages = pkgs.linuxPackages_latest;

in {
  boot.kernelPackages = lib.mkOverride 1100 patchedKernelPackages;

  assertions = [{
    assertion =
      lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.19.14";
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
