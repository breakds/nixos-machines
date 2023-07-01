{ config, lib, pkgs, ... }:

let info = (import ../data/service-registry.nix).syncthing;

in {
  config = {
    services.syncthing = {
      enable = true;
      dataDir = "/home/breakds/syncthing";
      user = "breakds";
      group = "users";
      overrideDevices = true;
      overrideFolders = true;
      guiAddress = "127.0.0.1:${toString info.gui.port}";
      devices = {
        "hand" = { id = "HDUZ6E3-ZMKCKOU-H6EYUET-XZ72BBU-547J5H2-BFEZFWM-DRX5YIR-23Z6TAH"; };
      };
    };
  };
}
