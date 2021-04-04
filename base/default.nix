# This is the base for all machines that is managed and serviced by
# Break and Cassandra.

{ config, lib, pkgs, ... }:

{
  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # Enable to use non-free packages such as nvidia drivers
  nixpkgs.config.allowUnfree = true;

  users.extraUsers = {
    "breakds" = {
      shell = pkgs.zsh;
      useDefaultShell = false;
    };
  };

  environment.systemPackages = with pkgs; [
    # TODO(breakds) texlive needs to be added separately in a module

    # Development
    emacs vim meld tig cmake clang clang-tools sbcl nodejs-14_x
    git gnumake gcc silver-searcher    
    
    # C++ Development
    include-what-you-use
    cgal

    # Lisp Development
    lispPackages.quicklisp

    # For Nix Development
    nixpkgs-review

    # TODO(breakds): Move to graphical

    # Tools
    httpie
    pass
    ledger
    graphviz
    graphicsmagick
    hugo
    quickserve
    gparted
    python3Packages.gdown
    pdftk
    remmina
    p7zip
    unzip
    arandr
    ffmpeg
    zstd 

    # Database and cloud
    mysql-client
    awscli2
    nixops
    smbclient
    nixops
  ] ++ lib.optionals config.vital.graphical.enable [
    feh
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
}