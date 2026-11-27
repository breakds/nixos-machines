{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./workaround.nix
  ];

  networking.hostName = "claw";
  networking.hostId = "8d3da45b";

  hardware.graphics.enable32Bit = false;

  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # HiDPI console font for the Framework 13's high-res display.
  # Include the font in initrd for the disk unlock prompt.
  console = {
    earlySetup = true;
    packages = [ pkgs.terminus_font ];
    font = "ter-132n";
  };
  home-manager.users.breakds.xresources.properties."Xft.dpi" = 144;

  # Keep the versions from the original installation.
  system.stateVersion = "25.11";
  home-manager.users.breakds.home.stateVersion = "25.11";
}
