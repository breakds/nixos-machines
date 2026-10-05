{ config, pkgs, lib, ... }:

let full = config.vital.development.profile == "full";

in {
  imports = [ ./lisp.nix ./perf.nix ];

  options.vital.development.profile = lib.mkOption {
    type = lib.types.enum [ "full" "light" ];
    default = "full";
    description = ''
      The light profile keeps editing, remote access, and basic CLI tools.
      The full profile adds local development and production tools.
      Both include Lisp and profiling tools.
    '';
  };

  config = {
    # For beekeeper-studio in environment.systemPackages below.
    vital.insecurePackages = lib.optionals full [ "beekeeper-studio-5.3.4" ];

    environment.systemPackages = with pkgs;
      [
        ripgrep
        rsync
        wget
        zip
        neovim
        tig
        rustdesk-flutter
        xh
        tmux
        zellij
        fd
        waypipe
        muxwarden
        bluetuith

        # System Tools
        lsof
        btop
        pciutils
        usbutils
        file
        p7zip
        unzip
        zstd

        # Font
        emacs-all-the-icons-fonts

        # Customized
        hunk

        # Nix specific
        nix-index
        nixos-container
        ragenix
      ] ++ lib.optionals full [
        silver-searcher
        cntr
        meld
        nixpkgs-review
        graphviz
        graphicsmagick
        pdftk
        ffmpeg
        vlc
        sqlitebrowser
        awscli2
        azure-cli
        azure-storage-azcopy
        miniserve # miniserve --index index.html --spa .
        pandoc
        marksman # Markdown Language Server
        forgejo-cli
        pv # pipe viewer
        asciinema
        wireshark
        duckdb
        websocat
        dmidecode
        powertop
        inetutils
        lm_sensors
        glances
        tio # Serial console TTY
        shuriken

        # For accouting
        beancount
        fava

        beekeeper-studio

        # C++
        clang

        # Nix specific
        nix-init
        nix-update
        cachix

        # Audio
        audacity
      ] ++ (let
        hasHM = config ? home-manager && config.home-manager.users ? "breakds";
        isSway = hasHM
          && config.home-manager.users."breakds".home.bds.windowManager
          == "sway";
        isGdmWayland = config.services.displayManager.gdm.enable;
        isWayland = isSway || isGdmWayland;
      in [ (if isWayland then pkgs.emacs-pgtk else pkgs.emacs) ]);

    programs.nix-ld.enable = true;
    programs.sysdig.enable = full;
    programs.zsh.enable = true;

    nix = {
      # The following is added to /etc/nix.conf to prevent GC from
      # deleting too many dependencies.
      extraOptions = lib.mkIf full ''
        keep-outputs = true
        keep-derivations = true
      '';
    };
  };
}
