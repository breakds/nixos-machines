{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../modules/syncthing.nix
    ../../base/vpn.nix
    ./services/clamav.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_malenia.pub
      ];
      shell = pkgs.zsh;
    };

    # Bootloader
    boot.loader.systemd-boot.enable = false;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

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
      # Disable UCM profiles to fix built-in microphone on Framework 13 AMD
      # Ryzen AI 300. See: https://github.com/NixOS/nixos-hardware/issues/1603
      wireplumber.extraConfig.no-ucm = {
        "monitor.alsa.properties" = {
          "alsa.use-ucm" = false;
        };
      };
    };

    # Machine-specific networking configuration.
    networking.hostName = "claw";
    networking.hostId = "8d3da45b";
    networking.useDHCP = lib.mkDefault true;

    vital.programs.arduino.enable = true;

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
      yt-dlp
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
      home.bds.location = "valley";
      # If you are not using a desktop environment such as KDE, Xfce, or other
      # that manipulates the X settings for you, you can set the desired DPI
      # setting manually via the Xft.dpi variable in Xresources:
      xresources.properties = {
        "Xft.dpi" = 144;
      };

      programs.texlive = {
        enable = true;
        extraPackages = tpkgs: { inherit (tpkgs) scheme-full; };
      };
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
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.11"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "25.11";
  };
}
