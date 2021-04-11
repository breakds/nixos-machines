{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    meld tig nodejs-14_x gnumake
    include-what-you-use cgal

    # Lisp Development
    sbcl
    lispPackages.quicklisp

    # For Nix Development
    nixpkgs-review

    # Other Tools
    httpie
    ledger
    graphviz
    graphicsmagick
    hugo
    quickserve
    python3Packages.gdown
    pdftk
    remmina
    ffmpeg

    # Database and cloud
    mysql-client
    awscli2
    nixops

    # Performance Tools
    sysstat
    linuxPackages.perf
    perf-tools # By Brendan Gregg
    flameGraph
  ];
}
