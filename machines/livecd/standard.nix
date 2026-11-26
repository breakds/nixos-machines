{config, pkgs, ...}:

{
  imports = [ ../../base/ssh-host-keys.nix ];

  config = {
    nixpkgs.config.allowUnfree = true;
    
    environment.systemPackages = with pkgs; [
      git
      emacs
      firefox
      gparted
      fd
      lsd
      bat
      silver-searcher
      duf
      dust
      feh
      pass

      # For vpn
      expressvpn
    ];

    services.expressvpn.enable = true;

    nix = {
      package = pkgs.nix;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };    
  };
}
