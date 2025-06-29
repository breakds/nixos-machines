{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../base/build-machines-v2.nix
    ../../base/dev/interbotix.nix
    ../../modules/syncthing.nix
    ../../base/vpn.nix
    # ./unison.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
      shell = pkgs.zsh;
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "brock"; # Define your hostname.
    networking.hostId = "20669241";
    networking.useDHCP = lib.mkDefault true;

    # Enable networking
    networking.networkmanager.enable = true;

    time.timeZone = "America/Los_Angeles";

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
    };

    # Select internationalisation properties.
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

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Quick Sync Video (hardware accelerated media conversion for Intel)
    # See https://wiki.nixos.org/wiki/Intel_Graphics
    # Also note, hardware.opengl will rename to `hardware.graphics` in 24.11
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vpl-gpu-rt
      ];
    };

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    programs.firefox.enable = true;
    environment.systemPackages = with pkgs; [
      zoom-us
      unetbootin
      pavucontrol
      xorg.xeyes
    ];

    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;

    # With the following, fcitx can work with xwayland (i.e. non-native wayland
    # windows).
    environment.sessionVariables = {
      NIX_PROFILES =
        "${lib.concatStringsSep " " (lib.reverseList config.environment.profiles)}";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    home-manager.users."breakds" = {
      home.bds.windowManager = "sway";
      home.bds.location = "valley";
      # If you are not using a desktop environment such as KDE, Xfce, or other
      # that manipulates the X settings for you, you can set the desired DPI
      # setting manually via the Xft.dpi variable in Xresources:
      xresources.properties = {
        "Xft.dpi" = 100;
      };
    };

    services.fwupd.enable = true;

    services.prometheus.exporters.node.enable = true;

    # +--------------------+
    # | VPN                |
    # +--------------------+

    vital.vpn = {
      clash = false;
      tailscale = false;
    };

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

    vital.distributed-build = {
      caches = [ "octavian" ];
      builders = [ "octavian" "malenia" ];
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "24.05";
  };
}
