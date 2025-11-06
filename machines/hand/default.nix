{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
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
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Framework Firmware Update
    #
    # sudo fwupdmgr update
    services.fwupd.enable = true;

    # Internationalisation
    i18n.defaultLocale = "en_US.UTF-8";

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Machine-specific networking configuration.
    networking.hostName = "hand";
    networking.hostId = "c5f97ee3";
    networking.useDHCP = lib.mkDefault true;

    vital.programs.arduino.enable = true;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      zoom-us
      thunderbird
      trezor-suite
      unetbootin
      pavucontrol
      parsec-bin  # For game streaming
      xorg.xeyes
      freecad
      serena
      obs-studio
      moonlight-qt
    ];

    xdg.mime = {
      enable = true;
      addedAssociations = {
        "application/pdf" = "sioyek.desktop";
      };
    };

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
      home.bds.location = "valley";
      # If you are not using a desktop environment such as KDE, Xfce, or other
      # that manipulates the X settings for you, you can set the desired DPI
      # setting manually via the Xft.dpi variable in Xresources:
      xresources.properties = {
        "Xft.dpi" = 144;
      };
      # Set the default scale to 1.0.
      wayland.windowManager.sway.config.output = {
        "eDP-1" = {
          scale = "1.0";
        };
      };
    };

    # +--------------------+
    # | Agent              |
    # +--------------------+

    programs.gooseit = {
      enable = true;
      model = "qwen3:30b";
    };

    # +--------------------+
    # | VPN                |
    # +--------------------+

    vital.vpn = {
      tailscale = true;
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
    system.stateVersion = "22.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "22.05";
  };
}
