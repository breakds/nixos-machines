{ inputs, ... }:

let self = inputs.self;

in {
  imports = [
    ./ollama/part.nix
    ./extra-mounts/part.nix
  ];
  
  flake.nixosModules = {
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

    temporal = import ./temporal;
    glance = import ./glance;
    gooseit = import ./gooseit.nix;
  };
}
