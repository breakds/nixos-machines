{ config, lib, pkgs, ... }:

{
  config = {
    programs = {
      gnupg.agent = {
        enable = true;
        enableSSHSupport = lib.mkDefault true;
        settings = {
          # Cache GPG passphrases for one hour idle, at most eight hours total.
          default-cache-ttl = lib.mkDefault 3600;
          max-cache-ttl = lib.mkDefault 28800;
        };
      };
      ssh.startAgent = lib.mkDefault false;
    };

    services.openssh = {
      enable = true;
      # Enable X11 Fowarding, can be connected with ssh -Y.
      settings.X11Forwarding = true;
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
  };
}
