{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    ../../modules/syncthing.nix
    ../../modules/localsend.nix
    # ./clickhouse
    # ./n8n
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    users.users."root" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    networking = {
      hostName = "malenia";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9cfcdd52";
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;

    home-manager.users."breakds" = {
      home.bds.windowManager = "i3";
    };

    environment.systemPackages = with pkgs; [
      gimp
      darktable
      go-ethereum
      filezilla
      woeusb
      axel
      audacious
      audacity
      zoom-us
      thunderbird
      mullvad-vpn
      unetbootin
      trezor-suite
      inkscape
      element-desktop
      parsec-bin  # For game streaming
      # python3Packages.archer
      blender
      openconnect
      anki
      flacon     # audiofile encoder
      pavucontrol
      aider-chat
    ];

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    # services.clickhouse-wonder = {
    #   enable = true;
    #   # TODO(breakds): Migrate this to dataset directory.
    #   workDir = "/home/breakds/dataset/clickhouse";
    #   backup = {
    #     name = "backups1";
    #     path = "/var/lib/wonder/warehouse/clickhouse/ClickHouseBackup";
    #   };
    # };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05";
    home-manager.users."breakds".home.stateVersion = "22.05";
  };
}
