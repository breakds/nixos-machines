{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../users
    ../../users/xiaozhu.nix
    ../../users/mujun.nix
    ../../base/dev/breakds-dev.nix
    ../../base/build-machines-v2.nix

    # Other modules
    ./services/web-services.nix
    ./services/monitor
    ./services/hydra.nix
    ./services/media.nix
    # ./services/code-server.nix
    # ./services/terraria.nix
    ./services/docker-registry.nix
    ./services/paperless.nix
    # ./services/game-solutions.nix
    ./services/temporal.nix
    ./services/bcounting.nix
    ./services/glance.nix
    ./services/rustdesk.nix
    ./services/karakeep.nix
    ./services/atuin.nix
    ../../base/vpn.nix
  ];

  config = {
    vital.mainUser = "breakds";

    services.openssh.settings.PasswordAuthentication = false;
    programs.gnupg.agent.enableSSHSupport = false;

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
        ../../data/keys/breakds_202405_sep.pub
      ];
    };

    users.users."borg" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/kj.pub
      ];
    };

    users.users."root" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
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

    vital.pre-installed.level = 5;

    vital.programs = {
      texlive.enable = false;
      modern-utils.enable = true;
    };

    environment.systemPackages = with pkgs; [
      lm_sensors
      smartmontools
    ];

    vital.graphical = {
      enable = true;
      nvidia = {
        enable = true;
        prime = {
          enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
          offload = true;
        };
      };
      # remote-desktop.enable = false;
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

    services.ollama.host = "0.0.0.0";
    services.open-webui.environment.OLLAMA_BASE_URLS = "http://10.77.1.128:11434";  # lorian
    services.personax-discord-bot.enable = true;

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
