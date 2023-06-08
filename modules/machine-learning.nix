# Provides configurations that supports running and maintaining machine learning
# experiments.

{ traintrack }:

{ config, pkgs, lib, ... }:

{
  config = {
    nixpkgs.overlays = [ traintrack.overlays.default ];
    
    environment.systemPackages = with pkgs; [
      nvitop
    ];
  };
}
