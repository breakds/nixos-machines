{ config, lib, pkgs, ... }:

let info = (import ../data/service-registry.nix).syncthing;

in {
  config = {
    services.syncthing = {
      enable = true;
      dataDir = "/home/${config.vital.mainUser}/syncthing";
      user = "breakds";
      group = "users";
      overrideDevices = true;
      overrideFolders = true;
      guiAddress = "127.0.0.1:${toString info.gui.port}";
      devices = {
        # Why do we only need to specify the IDs? Because syncthing will
        # automatically handle the discovery via various different and
        # complicated same-network and cross-network techniques. The ID (public
        # key fingerprint) here is only used to verify the identity of the
        # machines.
        "hand" = { id = "HDUZ6E3-ZMKCKOU-H6EYUET-XZ72BBU-547J5H2-BFEZFWM-DRX5YIR-23Z6TAH"; };
        "malenia" = { id = "RO54QTU-EJBHNA6-7IEMT2A-57UBFYH-N2USR7J-UN6A2ZL-G4W4AIV-DUFACAF"; };
        "samaritan" = { id = "FZHRPT7-SBV4Z4N-CHWNHQV-JDWY7N5-64AHNN3-J2HV5EL-EJ6ZY2R-3QOC6AZ"; };
      };

      folders = {
        
        "workspace" = {
          path = "/home/breakds/syncthing/workspace";
          devices = [ "hand" "malenia" "samaritan" ];
          ignorePerms = true;  # Do not sync the permissions.
          # Normally the sync is triggered by inotify (watch) so that it does
          # not need rescan. Still make full rescan happen every hour just to
          # make sure.
          rescanInterval = 3600;
          versioning = {
            type = "simple";
            params.keep = "5";
          };
        };

        "shared_checkpoints" = {
          path = "/home/${config.vital.mainUser}/dataset/shared_checkpoints";
          devices = [ "hyaku" "samaritan" ];
          ignorePerms = true;  # Do not sync the permissions.
          # Normally the sync is triggered by inotify (watch) so that it does
          # not need rescan. Still make full rescan happen every hour just to
          # make sure.
          rescanInterval = 3600;
          versioning = {
            type = "simple";
            params.keep = "5";
          };
        };
        
      };
    };
  };
}
