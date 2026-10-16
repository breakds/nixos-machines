{ config, pkgs, lib, ... }:

{
  imports = [
    ./i3-session-breakds.nix
    ./dev/breakds-dev.nix
    ../modules/syncthing.nix
    ./vpn.nix
    ../modules/clamav.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [ ../data/keys/breakds_malenia.pub ];
      shell = pkgs.zsh;
    };

    # Bootloader
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;

    # Firmware updates
    # sudo fwupdmgr update
    services.fwupd.enable = true;

    # Internationalisation
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.inputMethod.fcitx5.waylandFrontend = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    networking.useDHCP = lib.mkDefault true;

    vital.programs.arduino.enable = true;

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = { enable = true; };

    environment.systemPackages = with pkgs; [
      zoom-us
      thunderbird
      trezor-suite
      unetbootin
      pavucontrol
      parsec-bin # For game streaming
      xeyes
      freecad
      obs-studio
      moonlight-qt
      yt-dlp
      immich-cli
      mediainfo
    ];

    xdg.mime = {
      enable = true;
      addedAssociations = { "application/pdf" = "sioyek.desktop"; };
    };

    # NIXOS_OZONE_WL: Electron/Chromium apps use Wayland instead of X11.
    # Keep Fcitx support for Qt and X11 applications; GTK uses Wayland input.
    environment.sessionVariables = {
      NIX_PROFILES = "${lib.concatStringsSep " "
        (lib.reverseList config.environment.profiles)}";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      NIXOS_OZONE_WL = "1";
    };

    # This follows olmokramer's solution from this post:
    # https://discourse.nixos.org/t/configuring-caps-lock-as-control-on-console/9356/2
    services.udev.extraHwdb = ''
      evdev:input:b0011v0001p0001eAB83*
        KEYBOARD_KEY_3A=leftctrl    # CAPSLOCK -> CTRL
    '';

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    # Enroll fingerprints on each laptop with fprintd-enroll.
    services.fprintd.enable = true;

    home-manager.users."breakds" = {
      home.bds.laptopXsession = true;
      home.bds.location = "valley";
      programs.texlive = {
        enable = true;
        extraPackages = tpkgs: { inherit (tpkgs) scheme-full; };
      };
    };

    services.post-box = {
      enable = true;
      hostIp = "10.55.1.1";
      localIp = "10.55.1.2";
      user = "breakds";
      keyFiles = [ ../data/keys/breakds_malenia.pub ];
    };

    programs.skillful.skills = [
      "pr-anatomy"
      "cdp-test-companion"
    ];

    # +--------------------+
    # | VPN                |
    # +--------------------+

    vital.vpn = { tailscale = true; };

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

    vital.distributed-build = {
      caches = [ "octavian" ];
      builders = [ "octavian" "malenia" ];
    };

  };
}
