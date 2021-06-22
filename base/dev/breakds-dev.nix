{ config, pkgs, lib, ... }:

{
  imports = [
    ./lisp.nix
    ./perf.nix
    ./cpp.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      meld
      tig
      nixpkgs-review
      ledger
      graphviz
      graphicsmagick
      pdftk
      hugo
      quickserve
      remmina
      ffmpeg
      mysql-client
    ];
  };
}
