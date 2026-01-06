{ pkgs, config, lib, stt-server, ... }:

let reg = (import ../../../data/service-registry.nix).stt-server;

in {
  nixpkgs.overlays = [ stt-server.overlays.default ];

  services.stt-server = {
    inherit (reg) port;
    enable = true;
    device = "cuda";
    openFirewall = true;
  };
}
