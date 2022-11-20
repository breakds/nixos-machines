{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ./display.nix
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

    # Use the shiny linux kernel 6.0. With this kernel, the following will become supported
    #
    # 1. The HDMI module via the lightning port
    # 2. The i3 status bar which requires the backlight tuning
    #
    # And probably something else that I did not notice yet.
    boot.kernelPackages = pkgs.newLinuxPackages_6_0;

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

    # Machine-specific networking configuration.
    networking.hostName = "hand";
    networking.hostId = "c5f97ee3";
    networking.useDHCP = lib.mkDefault true;

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;
    vital.programs.arduino.enable = true;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;
    vital.programs.vscode.enable = false;

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
    ];

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
    };

    # nix = {
    #   distributedBuilds = true;
    #   buildMachines = [
    #     {
    #       hostName = "richelieu";
    #       systems = [ "x86_64-linux" "i686-linux" ];
    #       maxJobs = 24;
    #       supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    #     }
    #   ];
    #   settings = {
    #     trusted-substituters = [ "ssh://richelieu.local" ];
    #   };
    # };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?
  };
}
