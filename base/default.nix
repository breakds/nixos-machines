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
      gparted pass samba
      feh
      jq
      google-chrome
      tor-browser-bundle-bin
      scrot
      dmenu
      firefox
      arandr
      vim
      git
    ];

    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    fonts.packages = with pkgs; [
      # Use nerd-fonts for coding
      nerd-fonts.fira-code
      nerd-fonts.inconsolata
      nerd-fonts.jetbrains-mono
      # Add Wenquanyi Microsoft Ya Hei, a nice-looking Chinese font.
      wqy_microhei
      font-awesome
    ];
  };
}
