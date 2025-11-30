{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sysstat
    perf
    perf-tools  # By Brendan Gregg
    flamegraph
  ];
}
