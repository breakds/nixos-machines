{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    orca-slicer
  ];
}
