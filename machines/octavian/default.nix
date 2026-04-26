{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./delegator.nix
    ../../users
    ../../users/xin.nix
    ../../users/toph.nix
    ../../base/dev/breakds-dev.nix
    ../../base/build-machines-v2.nix

    # Other modules
    ./services/web-services.nix
    ./services/monitor
    ./services/hydra.nix
    ./services/immich.nix
    ./services/media.nix
    # ./services/code-server.nix
    # ./services/terraria.nix
    ./services/docker-registry.nix
    ./services/paperless.nix
    # ./services/game-solutions.nix
    ./services/glance.nix
    ./services/rustdesk.nix
    ./services/karakeep.nix
    ./services/atuin.nix
    ./services/home-assistant.nix
    ./services/solar-assistant.nix
    ./services/komga.nix
    ./services/stt-server.nix
    ./services/toylet-notes.nix
    ../../base/vpn.nix
  ];

  config = {
    vital.mainUser = "breakds";

    services.openssh.settings.PasswordAuthentication = false;
    programs.gnupg.agent.enableSSHSupport = false;

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_malenia.pub
      ];
    };

    users.users."borg" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/kj.pub
      ];
    };

    users.users."root" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_malenia.pub
      ];
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Allow sudo without password
    security.sudo.extraRules = [
      {
        users = [ "breakds" ];
        commands = [ { command = "ALL"; options = [ "NOPASSWD" ];} ];
      }
    ];

    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    networking = {
      hostName = "octavian";
      hostId = "e4f0c450";
      networkmanager.enable = true;
    };

    # Blacklist the on-board Intel I225 1G NIC driver. Home VLAN runs on
    # the 10G enp4s0f0 (ixgbe); the 1G port has no cable.
    #
    # This isn't a hardware preference — it's a workaround for an
    # upstream-acknowledged bug in matter-server's CHIP backend. CHIP
    # picks the "primary Ethernet interface" by walking getifaddrs() and
    # taking the first interface whose name starts with `en`/`eth`. On
    # this host that lands on enp6s0 (igc) instead of enp4s0f0. CHIP
    # then sends all mDNS/CASE UDP via the dead NIC, sendto() fails with
    # ENETUNREACH, Matter sessions to existing devices churn every ~80s
    # with `Subscription Liveness timeout`, and after a few hours the
    # controller silently wedges — process alive but doing no work,
    # blocking new device commissioning until restart.
    #
    # Upstream has no override flag for CHIP's choice — see
    # python-matter-server issues #493, #1010, #4028 and
    # connectedhomeip #42516, all closed as wontfix/stale. The community
    # workaround is to hide the wrong NIC from CHIP entirely. We
    # blacklist the driver rather than rename via systemd.network.links
    # so the device cleanly disappears from `ip addr` instead of leaving
    # a renamed orphan interface that future-debugging would chase.
    #
    # To re-enable the 1G port (e.g. for emergency wired access), remove
    # this line and reboot.
    boot.blacklistedKernelModules = [ "igc" ];

    environment.systemPackages = with pkgs; [
      lm_sensors
      smartmontools
    ];

    # Octavian is a headless home server — no desktop, boot to multi-user (tty).
    # Keep NVIDIA enabled separately for CUDA (immich, ollama).
    vital.graphical = {
      enable = false;
      nvidia = {
        enable = true;
        prime = {
          enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
          offload = true;
        };
      };
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };


    # +----------------+
    # | Services       |
    # +----------------+

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "bds@breakds.org";
      };
    };

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # TODO(breakds): Make this per virtual host.
      clientMaxBodySize = "1000m";
    };

    vital.services.filerun = {
      enable = true;
      workDir = "/var/lib/filerun";
      port = 5962;
      domain = "files.breakds.org";
    };

    services.borgbackup = {
      repos.orbekk = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKtA1xBORJKbH5roaYL2hmNraTCj0xYU4jEtvX8P6rAd root@dragon"
        ];
        path = /var/lib/borgbackup/orbekk;
      };
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "Sun, 02:00";
      };
    };

    services.postgresql = {
      package = pkgs.postgresql_18;
    };

    services.ollama.host = "0.0.0.0";
    services.open-webui.environment.OLLAMA_BASE_URLS = "http://10.77.1.128:11434";  # lorian

    nix = {
      settings = {
        max-jobs = lib.mkDefault 12;
        trusted-users = [
          "root"
        ];
      };
    };

    vital.vpn = {
      tailscale = true;
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "24.05";
  };
}
