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
      openssh.authorizedKeys.keyFiles = [ ../../data/keys/breakds_malenia.pub ];
      shell = pkgs.zsh;
    };

    # Bootloader
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;

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
    networking.hostName = "ghostberry";
    networking.hostId = "4acc106e";
    networking.useDHCP = lib.mkDefault true;

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = { enable = true; };

    # HiDPI console font. earlySetup copies the font into initrd so
    # systemd-vconsole-setup can find it before the Nix store is mounted.
    console = {
      earlySetup = true;
      packages = [ pkgs.terminus_font ];
      font = "ter-132n";
    };

    environment.systemPackages = with pkgs; [
      pavucontrol
      xeyes
      moonlight-qt
      yt-dlp
    ];

    xdg.mime = {
      enable = true;
      addedAssociations = { "application/pdf" = "sioyek.desktop"; };
    };

    # NIXOS_OZONE_WL: Electron/Chromium apps use Wayland instead of X11.
    # GTK_IM_MODULE, QT_IM_MODULE, XMODIFIERS: fcitx works with xwayland
    # (i.e. non-native wayland windows).
    environment.sessionVariables = {
      NIX_PROFILES = "${lib.concatStringsSep " "
        (lib.reverseList config.environment.profiles)}";
      GTK_IM_MODULE = "fcitx";
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

    home-manager.users."breakds" = {
      home.bds.laptopXsession = true;
      home.bds.location = "valley";
      # If you are not using a desktop environment such as KDE, Xfce, or other
      # that manipulates the X settings for you, you can set the desired DPI
      # setting manually via the Xft.dpi variable in Xresources:
      xresources.properties = { "Xft.dpi" = 144; };

      programs.texlive = {
        enable = true;
        extraPackages = tpkgs: { inherit (tpkgs) scheme-full; };
      };
    };

    programs.gnupg.agent = {
      enableSSHSupport = lib.mkForce false;
      enable = lib.mkForce false;
    };
    programs.ssh.startAgent = lib.mkForce false;

    services.post-box = {
      enable = true;
      hostIp = "10.55.1.1";
      localIp = "10.55.1.2";
      user = "breakds";
      keyFiles = [ ../../data/keys/breakds_malenia.pub ];
    };

    programs.skillful.skills = [ "pr-walkthrough" "cdp-test-companion" ];

    # +--------------------+
    # | VPN                |
    # +--------------------+

    vital.vpn = { tailscale = true; };

    # Build locally from source by default. This intentionally does not use the
    # valley builder/cache module that claw uses, and also disables upstream
    # binary substituters such as cache.nixos.org.
    nix.settings = {
      substituters = lib.mkForce [ ];
      trusted-public-keys = lib.mkForce [ ];
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
