{ config, pkgs, lib, ... }:

{
  imports = [
    ./lisp.nix
    ./perf.nix
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
      vlc
      mysql-client
      sqlitebrowser
      awscli
      # TODO(breakds): Re-enable this when the insecure poetry issue is resolved.
      # nixops_unstable
      python3Packages.tensorboard
      pv  # pipe viewer
      asciinema
      wireshark
      duckdb
      websocat
      parquet-tools

      # System Tools
      dmidecode

      # Customized
      shuriken
    ];

    programs.nix-ld.enable = true;
    programs.sysdig.enable = true;
    programs.zsh.enable = true;

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
