{ config, pkgs, lib, ... }:

{
  imports = [
    ./dev-server.nix
    ./prod-server.nix
  ];
}
