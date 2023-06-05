{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../base
    ../../../base/i3-session-breakds.nix
    ../common/vpn.nix
    ../../../base/dev/breakds-dev.nix
    # ../../../base/tailscale.nix
    ../../../users/lezhao.nix
  ];

  config = {
    vital.mainUser = "breakds";

    users.users."breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../../data/keys/breakds_samaritan.pub
      ];
      shell = pkgs.zsh;
    };

    # Machine-specific networking configuration.
    networking.hostName = "zero";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "26a47390";

    # For unitree
    networking.firewall.allowedUDPPortRanges= [
      {
        from = 9200;
        to = 9210;
      }
    ];

    vital.pre-installed.level = 5;
    vital.programs = {
      vscode.enable = true;
      texlive.enable = true;
      modern-utils.enable = true;
      accounting.enable = true;
      machine-learning.enable = true;
    };

    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
    };

    # This follows olmokramer's solution from this post:
    # https://discourse.nixos.org/t/configuring-caps-lock-as-control-on-console/9356/2
    services.udev.extraHwdb = ''
      evdev:input:b0011v0001p0001eAB54*
        KEYBOARD_KEY_3A=leftctrl    # CAPSLOCK -> CTRL
    '';


    environment.systemPackages = with pkgs; [
      zoom-us
      pavucontrol
      wireshark
    ];

    home-manager.users."breakds" = {
      home.bds.laptopXsession = true;
    };

    nix = {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "gail3";
          systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
          maxJobs = 12;
          speedFactor = 3;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
        {
          hostName = "samaritan";
          systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
          maxJobs = 24;
          speedFactor = 3;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
        {
          hostName = "radahn";
          systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
          maxJobs = 24;
          speedFactor = 5;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
      ];
      settings = {
        max-jobs = 8;
        trusted-substituters = [
          "ssh://gail3"
          "ssh://gail3.breakds.org"
          "ssh://samaritan"
          "ssh://samaritan.breakds.org"
          "ssh://radahn"
          "ssh://radahn.breakds.org"
          "ssh://www.breakds.org"
        ];
      };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "21.05";
  };
}
