{ inputs, ... }:

let self = inputs.self;

in {
  imports = [
    ./ollama/part.nix
    ./extra-mounts/part.nix
  ];

  flake.nixosModules = {
    vital-base = import ./vital-base;
    
    base-overlays = { config, lib, pkgs, ... }: {
      nixpkgs.overlays = [
        inputs.muxwarden.overlays.default
        (final: prev: rec {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
              cudaForwardcompat = true;
              cudaCapabilities = [ "7.5" "8.6" "8.9" "12.0" ];
            };
            overlays = [
              inputs.ml-pkgs.overlays.gen-ai
            ];
          };
          inherit (unstable) n8n glance gemini-cli claude-code codex ollama ollama-cuda home-assistant-custom-components psynker wyoming-faster-whisper serena;
          shuriken = final.callPackage ../pkgs/shuriken {};
        })
      ];
    };

    graphical = import ./graphical;
    iphone-connect = import ./iphone-connect.nix;
    machine-learning = import ./machine-learning.nix;
    flatpak = import ./flatpak.nix;
    steam = import ./steam.nix;
    laptop = import ./laptop.nix;

    wonder-devops = { config, lib, pkgs, ... }: {
      nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ];
    };

    overlay-wonder-devops = { config, lib, pkgs, ... }: {
      nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ];
    };

    builder-cache-valley = { config, lib, pkgs, ... }: {
      imports = [ ../base/build-machines-v2.nix ];
      config = {
        vital.distributed-build = {
          # Note that although "radahn" is not in the list by default, it is
          # always possible to manually specify it by
          #
          # --extra-substituters "http://10.77.1.35:17777"
          caches = [ "octavian" ];
          builders = lib.optionals (config.networking.hostName != "malenia") [ "octavian" ] ;
        };
      };
    };

    syncthing = import ./syncthing.nix;
    glance = import ./glance;
    prometheus-exporters = import ./prometheus/exporters.nix;
    localsend = import ./localsend.nix;
    coding-agent = import ./coding-agent;
    qmk = import ./qmk.nix;
    sunshine = import ./sunshine.nix;
    filerun = import ./filerun.nix;  # TODO(breakds): Upgrade filerun
    arduino = import ./arduino.nix;
  };
}
