{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
    # TODO(breakds): Add python environment
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    networking = {
      hostName = "samaritan";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9c4a63a8";
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      xserver.dpi = 100;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = true;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;

    # For ROS
    networking.firewall.allowedTCPPorts = [ 11311 ];

    environment.systemPackages = with pkgs; [
      gimp
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
    ];

    # Eth Mining
    services.ethminer = {
      enable = true;
      recheckInterval = 1000;
      toolkit = "cuda";
      wallet = "0xcdea2bD3AC8089e9aa02cC6CF5677574f76f0df2.samaritan3060Ti";
      pool = "us2.ethermine.org";
      stratumPort = 4444;
      maxPower = 240;
      registerMail = "";
      rig = "";
    };

    # Trezor cryptocurrency hardware wallet
    services.trezord.enable = true;

    # Start Mullvad Service. This is just a service and you will need
    # to manually start it with
    #
    # $ mullvad account set xxxxxxxxxxxxxxx
    # $ mullvad relay set location us # The location you want to appear you are
    # $ mullvad connect
    # $ mullvad disconnect
    #
    # Note that you can call
    # $ mullvad status
    # to check the status
    services.mullvad-vpn.enable = true;
    networking.firewall.checkReversePath = "loose";  # This is a temporary hack for mullvad-vpn

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.03"; # Did you read the comment?
  };
}
