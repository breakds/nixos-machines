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
    networking.hostName = "berry";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "fe156831";

    # NOTE: there is a service called `dlm.service` for displaylink. I am not
    # pretty sure about the internals, but you will need the service to be
    # running normal first. After that, you will need to reboot the machine for
    # displaylink to work.
    #
    # Also it seems that displaylink 5.6 is bad. It is reported 5.5 is good, and
    # 5.6.1 seems to be good too.
    services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
    services.fwupd.enable = true;
    
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

    vital.programs = {
      modern-utils.enable = true;
      vscode.enable = false; # Use the one from home-manager
    };

    environment.systemPackages = with pkgs; [
      dbeaver
      gimp peek gnupg pass libreoffice
      skypeforlinux
      multitail
      nodejs-14_x
      (yarn.override { nodejs = nodejs-14_x; })
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
      enable = true;
      location = "homelab";
    };

    # This value determines the NixOS release from which the default settings
    # for stateful data, like file locations and database versions on your
    # system were taken. It‘s perfectly fine and recommended to leave this value
    # at the release version of the first install of this system. Before
    # changing this value read the documentation for this option (e.g. man
    # configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
    home-manager.users."cassandra".home.stateVersion = "21.05";
  };
}
