{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/build-machines.nix
    ./medea-clipper.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    networking = {
      hostName = "medea";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9d5e62c8";
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      xserver.displayManager = "lightdm";
    };

    services.xserver.desktopManager = {
      gnome.enable = lib.mkForce false;
      pantheon.enable = true;
    };

    services.xserver.displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "breakds";
    };

    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = false;
    vital.programs.modern-utils.enable = true;
    vital.programs.vscode.enable = false;

    environment.systemPackages = with pkgs; [
      plex-media-player
    ];

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

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
    system.stateVersion = "22.11"; # Did you read the comment?
  };
}
