{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../base/famass.nix
  ];

  config = let
    famass-registry = (import ../../../data/service-registry.nix).famass;
  in {
    services.famass = {
      enable = true;
      port = famass-registry.port;
      domain = famass-registry.domain;
      dataDir = "/home/breakds/dataset/yang";
      user = "breakds";
      group = "breakds";
    };
  };
}
