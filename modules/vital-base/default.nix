# The module `vital-base` is designed to serve as the foundation for all my servers.

{ config, lib, pkgs, ... }:

{
  imports = [
    ./main-user.nix
    ./vm.nix
    ./network-base.nix
    ../oci-tooling.nix
    ../priting.nix
  ];

  config = {
    boot = {
      loader.systemd-boot.enable = lib.mkDefault true;
      loader.efi.canTouchEfiVariables = lib.mkDefault true;
      # Filesystem Support
      supportedFilesystems = [ "ntfs" ];
    };


    time.timeZone = lib.mkDefault "America/Los_Angeles";

    # Enable to use non-free packages such as nvidia drivers
    nixpkgs.config.allowUnfree = true;

    # Override the default shell to zsh for breakds
    users.extraUsers = lib.mkIf (config.vital.mainUser == "breakds") {
      "breakds" = {
        shell = lib.mkDefault pkgs.zsh;
        useDefaultShell = false;
      };
    };

    networking.enableIPv6 = true;
    networking.usePredictableInterfaceNames = true;

    environment.systemPackages = with pkgs; [
      gparted samba
      (pass.withExtensions (exts: [ exts.pass-otp ]))
      feh
      jq
      google-chrome
      tor-browser
      scrot
      dmenu
      firefox
      arandr
      vim
      git
      duf
      lsd
      bat
      dust
    ];

    fonts.packages = with pkgs; [
      # Use nerd-fonts for coding
      nerd-fonts.fira-code
      nerd-fonts.inconsolata
      nerd-fonts.jetbrains-mono
      # Add Wenquanyi Microsoft Ya Hei, a nice-looking Chinese font.
      wqy_microhei
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
    ];

    programs.bash.completion.enable = true;

    services.udev.packages = [ pkgs.libu2f-host ];
    # Disable UDisks by default (significantly reduces system closure size)
    services.udisks2.enable = lib.mkDefault false;
    services.blueman.enable = true;

    nix = {
      package = pkgs.nix;
      settings.experimental-features = [ "nix-command" "flakes" ];

      # Automatically optimize storage spaces /nix/store
      settings = {
        auto-optimise-store = true;
      };

      # Automatic garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 120d";
      };
    };
  };
}
