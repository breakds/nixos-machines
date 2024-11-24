# Provides configurations that supports running and maintaining machine learning
# experiments.

{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      nvitop
    ];
  };
}
