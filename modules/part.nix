{ inputs, ... }:

let self = inputs.self;

in {
  imports = [
    ./ollama/part.nix
    ./extra-mounts/part.nix
  ];
  
  flake.nixosModules = {
    base-overlays = { config, lib, pkgs, ... }: {
      nixpkgs.overlays = [
        (final: prev: rec {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) system config;
            overlays = [
              inputs.psynker-flake.overlays.default
            ];
          };
          inherit (unstable) n8n glance gemini-cli claude-code ollama home-assistant-custom-components psynker;
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
    temporal = import ./temporal;
    glance = import ./glance;
    gooseit = import ./gooseit.nix;
    prometheus-exporters = import ./prometheus/exporters.nix;
    localsend = import ./localsend.nix;
    claude-code = import ./claude-code;
  };
}
