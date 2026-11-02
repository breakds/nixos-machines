# The Arm-based aarch64 machines needs a different base.

{ config, lib, pkgs, ... }:

{
  # The pinned nixos-hardware Pi kernel predates the IPv4 fix. Preserve its
  # Pi-specific drivers and backport the upstream fix until it catches up.
  boot.kernelPatches = lib.optional
    (lib.versionOlder config.boot.kernelPackages.kernel.version "6.12.113"
      || (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.18"
        && lib.versionOlder config.boot.kernelPackages.kernel.version "6.18.56")) {
      name = "CVE-2026-98432";
      patch = pkgs.fetchurl {
        url = "https://github.com/gregkh/linux/commit/11a03ce3c4a62d84c10ccdfe47f8075006498568.patch";
        hash = "sha256-LpyJGxpx/2FHp1u6ELS/ggUK0mhl8FFyDqaiwtuucD4=";
      };
    };

  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # Enable to use non-free packages such as nvidia drivers
  nixpkgs.config.allowUnfree = true;

  # Note: base overlays are now wired in via `self.nixosModules.base-overlays`
  # at the part.nix level (see machines/pi/part.nix), matching the post-July-2025
  # refactor done for the non-Pi machines.

  # TODO(breakds): Override the default shell to zsh for breakds
  users.extraUsers = lib.mkIf (config.vital.mainUser == "breakds") {
    "breakds" = {
      openssh.authorizedKeys.keyFiles = [
        ../../data/keys/breakds_malenia.pub
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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
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
    nssmdns4 = true;

    # Whether to register mDNS address records for all local IP
    # addresses.
    publish.enable = true;
    publish.addresses = true;
  };

  services.blueman.enable = true;

  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;

  nix = {
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
