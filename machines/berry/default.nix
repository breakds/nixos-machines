{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./displaylink.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../base/build-machines.nix
    ../../base/dev/interbotix.nix
    ../../modules/steam-run.nix
    ../../modules/syncthing.nix
    ../../base/vpn.nix
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

    networking.hostName = "berry"; # Define your hostname.
    networking.hostId = "fe156831";
    networking.useDHCP = lib.mkDefault true;

    # Enable networking
    networking.networkmanager.enable = true;

    time.timeZone = "Asia/Shanghai";

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      # xserver.dpi = 180;
    };

    # Enable displaylink for berry.
    # services.xserver.videoDrivers = [ "displaylink" ];

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

    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
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
      thunderbird
      trezor-suite
      unetbootin
      pavucontrol
      parsec-bin  # For game streaming
      xorg.xeyes
    ];

    vital.pre-installed.level = 5;
    vital.programs.arduino.enable = true;
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

    # This follows olmokramer's solution from this post:
    # https://discourse.nixos.org/t/configuring-caps-lock-as-control-on-console/9356/2
    services.udev.extraHwdb = ''
      evdev:input:b0011v0001p0001eAB83*
        KEYBOARD_KEY_3A=leftctrl    # CAPSLOCK -> CTRL
    '';

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    # The framework laptop supports fingerprint.
    services.fprintd.enable = true;

    home-manager.users."breakds" = {
      home.bds.laptopXsession = true;
      home.bds.windowManager = "sway";
    };

    services.fwupd.enable = true;

    # +--------------------+
    # | VPN                |
    # +--------------------+
    
    vital.vpn = {
      clash = true;
      tailscale = true;
    };

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

    vital.distributed-build = {
      enable = false;
      location = "office";
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
