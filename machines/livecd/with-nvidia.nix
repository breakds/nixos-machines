{config, pkgs, ...}:

{
  config = {
    nixpkgs.config.allowUnfree = true;
    
    environment.systemPackages = with pkgs; [
      git emacs firefox
      gparted
      fd lsd bat silver-searcher duf du-dust
    ];

    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
      experimental-features = nix-command flakes
    '';
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
