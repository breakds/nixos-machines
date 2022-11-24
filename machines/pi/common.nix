# The Arm-based aarch64 machines needs a different base.

{ config, lib, pkgs, ... }:

{
  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # Enable to use non-free packages such as nvidia drivers
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (import ../../base/overlays)
  ];

  # Override the default shell to zsh for breakds
  users.extraUsers = lib.mkIf (config.vital.mainUser == "breakds") {
    "breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
      shell = lib.mkDefault pkgs.zsh;
      useDefaultShell = false;
    };
  };

  networking.enableIPv6 = true;

  environment.systemPackages = with pkgs; [
    gparted pass
  ];
}
