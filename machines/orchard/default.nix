{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/build-machines.nix
  ];

  config = {
    vital.mainUser = "cassandra";

    # Machine-specific networking configuration.
    networking.hostName = "orchard";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "865cf75d";

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    services.fwupd.enable = true;
    services.printing.enable = true;

    # +----------+
    # | Sound    |
    # +----------+

    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    
  
    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
    };

    # +----------+
    # | Packages |
    # +----------+

    vital.pre-installed.level = 5;

    vital.programs = {
      texlive.enable = false;
      modern-utils.enable = true;
      vscode.enable = false; # Use the one from home-manager
    };

    # TODO(breakds): Add node back

    # NodeJS 14 is now deprecated. This makes sure that we can still use it.
    # nixpkgs.config.permittedInsecurePackages = [
    #   "nodejs-14.21.3"
    #   "openssl-1.1.1u"
    # ];

    environment.systemPackages = with pkgs; [
      firefox
      dbeaver
      gimp peek gnupg pass libreoffice
      skypeforlinux
      multitail
      # nodejs-14_x
      # (yarn.override { nodejs = nodejs-14_x; })
    ];

    # +----------+
    # | VPN      |
    # +----------+

    services.openvpn.servers = {
      MachineSP = {
        config = "config /home/cassandra/.config/vpn/machine_sp.conf";
        autoStart = false;
      };
    };

    # +--------------------+
    # | Distributed Build  |
    # +--------------------+

    vital.distributed-build = {
      # TODO(breakds): Enable this when needed.
      enable = false;
      location = "homelab";
    };

    # This value determines the NixOS release from which the default settings
    # for stateful data, like file locations and database versions on your
    # system were taken. It‘s perfectly fine and recommended to leave this value
    # at the release version of the first install of this system. Before
    # changing this value read the documentation for this option (e.g. man
    # configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?
    home-manager.users."cassandra".home.stateVersion = "23.11";
  };
}
