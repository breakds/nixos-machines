# This is the base for all machines that is managed and serviced by
# Break and Cassandra.

{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/oci-tooling.nix
    ../modules/priting.nix
  ];
  
  config = {
    time.timeZone = lib.mkDefault "America/Los_Angeles";

    # Enable to use non-free packages such as nvidia drivers
    nixpkgs.config.allowUnfree = true;

    nixpkgs.overlays = [
      (import ./overlays)
    ];

    # Override the default shell to zsh for breakds
    users.extraUsers = lib.mkIf (config.vital.mainUser == "breakds") {
      "breakds" = {
        shell = lib.mkDefault pkgs.zsh;
        useDefaultShell = false;
      };
    };

    networking.enableIPv6 = true;

    environment.systemPackages = with pkgs; [
      gparted pass samba
    ] ++ lib.optionals config.vital.graphical.enable [
      feh
      jq
      google-chrome
      scrot
      # Move to desktop specific modules
      # zoom-us
      # thunderbird     
      # strawberry
      # audacious
      # audacity
      # steam-run-native
      # wesnoth
      # inkscape
      # discord
    ];

    fonts.packages = with pkgs; [
      # Add Wenquanyi Microsoft Ya Hei, a nice-looking Chinese font.
      wqy_microhei
      # Fira code is a good font for coding
      fira-code
      fira-code-symbols
      font-awesome
      inconsolata
    ];

    # Create a better default environment for bash
    environment.etc = {
      "bashrc.local".source = ../data/dotfiles/bashrc.local;
      "inputrc".source = ../data/dotfiles/inputrc;
    };
  };
}
