{ lib, config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/build-machines.nix
    ../../modules/syncthing.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

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
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "004a3a44";
    };

    vital.graphical = {
      enable = true;
      nvidia.enable = false;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = false;
    vital.programs.modern-utils.enable = true;

    environment.systemPackages = with pkgs; [
      zoom-us
    ];

    vital.distributed-build = {
      enable = false;  # disabled so that we rely only on the WiFi
      location = "homelab";
    };

    # Disable unified cgroup hierarchy (cgroups v2)
    # This is to applease nvidia-docker
    systemd.enableUnifiedCgroupHierarchy = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "23.05";
  };
}
