{ config, lib, pkgs, ... }:

let registry = (import ../../data/service-registry.nix).glance;
    assets = pkgs.symlinkJoin {
      name = "glance-assets";
      paths = [ ./assets ];
    };

in {
  services.glance = {
    settings = {
      server = {
        host = "0.0.0.0";
        port = registry.port;
        assets-path = "${assets}";
      };

      theme = {
        background-color = "225 14 15";
        primary-color = "157 47 65";
        contrast-multiplier = 1.1;
        text-saturation-multiplier = 0.5;
        custom-css-file = "/assets/custom.css";
      };
      pages = [
        (import ./pages/home.nix)
        (import ./pages/entertainment.nix)
      ];
    };
  };
}
