{ pkgs, config, lib, stt-server, ... }:

let reg = (import ../../../data/service-registry.nix).stt-server;

in {
  services.stt-server = {
    inherit (reg) port;
    enable = true;
    device = "cuda";
    openFirewall = true;
  };
}
