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
      awscli
    ];

    nix = {
      # The following is added to /etc/nix.conf to prevent GC from
      # deleting too many dependencies.
      extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
    };
  };
}
