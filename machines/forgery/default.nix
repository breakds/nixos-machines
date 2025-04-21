{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/dev/breakds-dev.nix
    ../../users
    ../../base/build-machines-v2.nix
  ];

  config = {
    vital.mainUser = "breakds";

    services.openssh.settings.PasswordAuthentication = false;
    programs.gnupg.agent.enableSSHSupport = false;

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    users.users."root" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Allow sudo without password
    security.sudo.extraRules = [
      {
        users = [ "breakds" ];
        commands = [ { command = "ALL"; options = [ "NOPASSWD" ];} ];
      }
    ];

    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    networking = {
      hostName = "forgery";
      hostId = "6869bc25";
      networkmanager.enable = true;
    };

    vital.pre-installed.level = 5;

    vital.programs = {
      texlive.enable = false;
      modern-utils.enable = true;
    };

    environment.systemPackages = with pkgs; [
      lm_sensors
      smartmontools
    ];

    vital.graphical.enable = true;

    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # +----------------+
    # | Services       |
    # +----------------+

    nix = {
      settings = {
        max-jobs = lib.mkDefault 4;
        trusted-users = [
          "root"
        ];
      };
    };

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

    vital.distributed-build = {
      caches = [ "octavian" ];
      builders = [ "octavian" ];
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "24.11";
  };
}
