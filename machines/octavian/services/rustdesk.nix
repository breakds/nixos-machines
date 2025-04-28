{ config, lib, pkgs, ... }:

{
  # This is strictly for use within the home network. The ID server should be at
  # `octavian.local:21115`, and the relay servers are not necessary under such
  # scenario.
  services.rustdesk-server = {
    enable = true;
    signal.enable = true;
    signal.extraArgs = [
      "--mask" "10.77.1.0/24"
      "-M" "33554432"  # Larger UDP buffer
    ];
    openFirewall = true;
  };
}
