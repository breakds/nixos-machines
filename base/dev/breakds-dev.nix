{ config, pkgs, lib, ... }:

{
  imports = [
    ./lisp.nix
    ./perf.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      ripgrep
      silver-searcher
      rsync
      wget
      pinentry
      neovim
      cntr
      meld
      tig
      nixpkgs-review
      graphviz
      graphicsmagick
      pdftk
      rustdesk-flutter
      ffmpeg
      vlc
      mysql-client
      sqlitebrowser
      awscli
      azure-cli
      azure-storage-azcopy
      miniserve  # miniserve --index index.html --spa .
      # TODO(breakds): Re-enable this when the insecure poetry issue is resolved.
      # nixops_unstable
      tmux
      fd

      pv  # pipe viewer
      asciinema
      wireshark
      duckdb
      websocat
      bluetuith

      # System Tools
      dmidecode
      powertop
      lsof
      btop
      pciutils
      usbutils
      inetutils
      file
      p7zip
      unzip
      zstd
      meld
      lm_sensors

      # Customized
      shuriken

      # For accouting
      beancount
      fava

      dbeaver-bin

      # C++
      clang

      # Nix specific
      nix-index
      nix-init
      cachix

      # Agent
      gemini-cli
    ] ++ (let
      hasHM = config ? home-manager && config.home-manager.users ? "breakds";
      isWayland = hasHM && config.home-manager.users."breakds".home.bds.windowManager == "sway";
    in [(if isWayland then pkgs.emacs-pgtk else pkgs.emacs)]);

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
