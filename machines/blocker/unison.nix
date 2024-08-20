{ config, pkgs, lib, ... }:

{
  home-manager.users."breakds" = {
    home.packages = with pkgs; [
      unison
    ];
    services.unison = {
      enable = true;
      # Note that this requires `unison` installed on the remote machine. Can
      # just add it in `home.packages`.
      pairs = {
        "research-incubator" = {
          roots = [
            "/home/breakds/projects/quant/research-incubator"
            "ssh://ares//home/breakds/projects/research-incubator"
          ];
        };
      };
    };
  };
}
