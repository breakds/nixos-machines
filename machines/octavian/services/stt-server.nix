{ pkgs, config, lib, stt-server, ... }:

let reg = (import ../../../data/service-registry.nix).stt-server;

in {
  services.stt-server = {
    inherit (reg) port;
    # Disabled: STT holds ~8.7 GB on the T4, leaving too little VRAM for
    # Immich's ML sidecar (CLIP ViT-H-14-378). Re-enable once STT moves to
    # another GPU or a smaller whisper variant is configured.
    enable = false;
    device = "cuda";
    openFirewall = true;
  };
}
