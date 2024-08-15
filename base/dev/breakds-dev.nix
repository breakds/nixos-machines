{ config, pkgs, lib, ... }:

{
  imports = [
    ./lisp.nix
    ./perf.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      neovim
      cntr
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
      bluetuith  # Bluetooth Manager TUI
      # TODO(brakds): Cannot build at 23.05
      # parquet-tools
      unison

      # For SD Card and Images
      usbimager

      # System Tools
      dmidecode

      # Customized
      shuriken

      # For accouting
      beancount
      fava

      # For copilot
      nodejs

      nix-index
    ];

    programs.nix-ld.enable = true;
    programs.sysdig.enable = true;
    programs.zsh.enable = true;
    programs.sharing.enable = true;  # Will open 7478 port

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
