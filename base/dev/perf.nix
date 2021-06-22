{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sysstat
    linuxPackages.perf
    perf-tools  # By Brendan Gregg
    flameGraph
  ];
}
