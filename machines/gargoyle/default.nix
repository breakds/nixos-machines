# Gargoyle is a smart display powered by a minisforum Ryzen 4500U mini PC.

{ lib, config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/build-machines.nix
    ./services/interm.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      shell = pkgs.bash;
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Internationalisation
    i18n.defaultLocale = "en_US.utf8";

    # Enable sound with pipewire.
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    networking = {
      hostName = "gargoyle";
      hostId = "bbdf0382";
    };

    programs.gnupg.agent.enable = lib.mkForce false;
    programs.ssh.startAgent = lib.mkForce true;

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = false;
    vital.programs.modern-utils.enable = true;

    # KDE
    services.xserver.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6 = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      zoom-us
      strawberry
    ];

    vital.distributed-build = {
      enable = true;
      location = "homelab";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.05"; # Did you read the comment?
  };
}
