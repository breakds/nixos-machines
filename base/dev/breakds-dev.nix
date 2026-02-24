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
      zip
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
      sqlitebrowser
      awscli2
      azure-cli
      azure-storage-azcopy
      xh
      miniserve  # miniserve --index index.html --spa .
      # TODO(breakds): Re-enable this when the insecure poetry issue is resolved.
      # nixops_unstable
      tmux
      fd
      pandoc
      marksman  # Markdown Language Server
      waypipe
      muxwarden

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
      glances
      tio  # Serieal console TTY

      # Font
      emacs-all-the-icons-fonts

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
      nix-update
      nixos-container
      cachix
      ragenix

      # Audio
      audacity
    ] ++ (let
      hasHM = config ? home-manager && config.home-manager.users ? "breakds";
      isSway = hasHM && config.home-manager.users."breakds".home.bds.windowManager == "sway";
      isGdmWayland = config.services.displayManager.gdm.enable && config.services.displayManager.gdm.wayland;
      isWayland = isSway || isGdmWayland;
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
