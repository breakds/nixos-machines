{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    openconnect
  ];
}
