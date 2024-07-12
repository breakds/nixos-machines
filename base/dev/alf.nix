{ config, pkgs, ... }:

{
  nix.registry = {
    alf-nix-devenv = {
      from = { type = "indirect"; id = "alf-nix-devenv"; };
      to = { type = "path"; path = "/home/breakds/projects/horizon/alf-nix-devenv"; };
    };
  };
}
