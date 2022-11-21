{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
    ../../base/i3-session-breakds.nix
    ../../base/dev/breakds-dev.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Use the shiny linux kernel 6.0 for the Ryzen 9 7950x.
    boot.kernelPackages = pkgs.newLinuxPackages_6_0;
    hardware.nvidia.package = pkgs.newLinuxPackages_6_0.nvidiaPackages.stable;

    networking = {
      hostName = "malenia";
      # Generated via `head -c 8 /etc/machine-id`
      hostId = "9cfcdd52";
    };

    vital.graphical = {
      enable = true;
      remote-desktop.enable = true;
      nvidia.enable = true;
    };

    vital.pre-installed.level = 5;
    vital.games.steam.enable = true;
    vital.programs.texlive.enable = true;
    vital.programs.modern-utils.enable = true;
    vital.programs.accounting.enable = true;
    vital.programs.machine-learning.enable = true;

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
    ];

    # nix = {
    #   settings = {
    #     trusted-substituters = [ "ssh://richelieu.local" ];
    #   };
    # };

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

    # Disable unified cgroup hierarchy (cgroups v2)
    # This is to applease nvidia-docker
    systemd.enableUnifiedCgroupHierarchy = false;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05";
  };
}
