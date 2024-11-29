# The Arm-based aarch64 machines needs a different base.

{ config, lib, pkgs, ... }:

{
  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # Enable to use non-free packages such as nvidia drivers
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (import ../../base/overlays)
  ];

  # TODO(breakds): Override the default shell to zsh for breakds
  users.extraUsers = lib.mkIf (config.vital.mainUser == "breakds") {
    "breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_samaritan.pub
      ];
      shell = lib.mkDefault pkgs.bash;
      useDefaultShell = false;
    };
  };

  networking.enableIPv6 = true;

  environment.systemPackages = with pkgs; [
    gparted pass openconnect tmux
  ];

  # ------ Part of foundation reimplemented ------

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.completion.enable = true;
  # TODO(breakds): Figure out how to use GPG.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "tty";
  };

  programs.ssh.startAgent = lib.mkDefault false;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
  };

  services.avahi = {
    enable = true;

    # Whether to enable the mDNS NSS (Name Service Switch) plugin.
    # Enabling this allows applications to resolve names in the
    # `.local` domain.
    nssmdns = true;

    # Whether to register mDNS address records for all local IP
    # addresses.
    publish.enable = true;
    publish.addresses = true;
  };

  services.blueman.enable = true;

  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;

  nix = {
    # The following is to enable Nix Flakes
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';


    settings = {
      # Automatically optimize storage spaces /nix/store
      auto-optimise-store = true;
    };

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 120d";
    };
  };
}
