{
  config,
  lib,
  pkgs,
  ...
}:

let enabled = false;

in {
  services.clamav = {
    daemon = {
      enable = enabled;
      settings = {
        # Log to syslog for audit trail
        LogSyslog = true;
        LogTime = true;
        MaxThreads = 2;
      };
    };

    # Keep virus definitions updated, once daily
    updater = {
      enable = enabled;
      interval = "daily";
      frequency = 1;
    };

    # Weekly scan
    scanner = {
      enable = enabled;
      interval = "weekly";
      scanDirectories = [
        "/home/breakds/projects"
        "/home/breakds/tmp"
        "/home/breakds/Downloads"
        "/home/breakds/syncthing"
      ];
    };
  };

  # Make clamscan available for manual scans
  environment.systemPackages = [ pkgs.clamav ];
}
