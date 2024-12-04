{ inputs, ... }:

let self = inputs.self;

in {
  imports = [
    ./ollama/part.nix
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
          caches = [ "octavian" ];
          builders = [ "octavian" ] ++ lib.optionals (
            config.networking.hostName != "malenia") [ "malenia" ] ;
        };
      };
    };
  };
}
