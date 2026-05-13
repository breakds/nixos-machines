# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  mediaDir = "/home/kiosk/Videos";

  kioskRunner = pkgs.writeShellScript "olden-kiosk-runner" ''
    set -u

    while true; do
      if ${pkgs.findutils}/bin/find "${mediaDir}" -maxdepth 1 -type f \
          \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.webm' -o -iname '*.m4v' \) \
          | ${pkgs.gnugrep}/bin/grep -q .; then
        echo "olden-kiosk: starting mpv"
        ${pkgs.mpv}/bin/mpv \
          --fullscreen \
          --loop-playlist=inf \
          --no-osc \
          --no-input-default-bindings \
          --cursor-autohide=always \
          --hwdec=auto-safe \
          "${mediaDir}"
        echo "olden-kiosk: mpv exited; restarting in 5s"
      else
        echo "olden-kiosk: waiting for videos in ${mediaDir}"
      fi

      sleep 5
    done
  '';

in {
  imports = [ ./hardware-configuration.nix ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [ ../../data/keys/breakds_malenia.pub ];
      shell = pkgs.zsh;
    };

    users.users.kiosk = {
      isNormalUser = true;
      home = "/home/kiosk";
      createHome = true;
      extraGroups = [ "video" "audio" "render" "input" ];
    };

    programs.zsh.enable = true;

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelParams = [ "consoleblank=0" ];

    networking.hostName = "olden"; # Define your hostname.
    networking.hostId = "7E689A4B";
    networking.useDHCP = lib.mkDefault true;

    # Enable networking
    networking.networkmanager.enable = true;

    # Set your time zone.
    time.timeZone = "America/Los_Angeles";

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

    hardware.graphics.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    systemd.tmpfiles.rules = [ "d ${mediaDir} 0755 kiosk kiosk -" ];

    services.cage = {
      enable = true;
      user = "kiosk";
      program = "${kioskRunner}";
    };

    systemd.services."cage-tty1".serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 0;
    };

    environment.systemPackages = with pkgs; [ mpv vim git ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.11"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "25.11";
  };
}
