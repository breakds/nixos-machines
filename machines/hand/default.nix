{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../base/build-machines.nix
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
    boot.kernelPackages = pkgs.linuxPackages_6_0;

    # [HACK] This is a temporary fix to the constant freeze when using emacs. According to the
    # forum of Framework, this is caused by the PSR in i915. Disabling it will cause the laptop
    # to be slightly less power efficient. Should definitely remove this when the new kernel
    # with an updated i915 driver comes.
    # boot.kernelParams = [ "i915.enable_psr=0" ];

    # Framework Firmware Update
    #
    # sudo fwupdmgr update
    services.fwupd.enable = true;

    services.tlp.extraConfig = ''
      START_CHARGE_THRESH_BAT0=80
      STOP_CHARGE_THRESH_BAT0=95
      CPU_SCALING_GOVERNOR_ON_BAT=powersave
      ENERGY_PERF_POLICY_ON_BAT=powersave
    '';    

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
      xserver.dpi = 120;
    };

    environment.systemPackages = with pkgs; [
      zoom-us
      thunderbird
      trezor-suite
      unetbootin
      pavucontrol
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

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

    nix.buildMachines = [{
      hostName = "localhost";
      systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      maxJobs = lib.mkDefault 12;
      speedFactor = lib.mkDefault 2;
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ]; 
    }];

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
