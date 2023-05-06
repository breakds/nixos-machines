{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/build-machines.nix
  ];

  config = {
    vital.mainUser = "cassandra";

    # Machine-specific networking configuration.
    networking.hostName = "berry";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "fe156831";

    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
    
    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      xserver.dpi = 120;
    };

    # +----------+
    # | Packages |
    # +----------+

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    vital.programs = {
      modern-utils.enable = true;
      vscode.enable = false; # Use the one from home-manager
    };

    environment.systemPackages = with pkgs; [
      dbeaver
      gimp peek gnupg pass libreoffice
      skypeforlinux
      multitail
      nodejs-18_x
      (yarn.override { nodejs = nodejs-18_x; })
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

    nix.buildMachines = [{
      hostName = "localhost";
      systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      maxJobs = lib.mkDefault 7;
      speedFactor = lib.mkDefault 2;
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    }];

    # This value determines the NixOS release from which the default settings
    # for stateful data, like file locations and database versions on your
    # system were taken. It‘s perfectly fine and recommended to leave this value
    # at the release version of the first install of this system. Before
    # changing this value read the documentation for this option (e.g. man
    # configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
  };
}
