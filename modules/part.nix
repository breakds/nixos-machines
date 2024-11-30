{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosModules = {
    graphical = import ./graphical;
    iphone-connect = import ./iphone-connect.nix;
    machine-learning = import ./machine-learning.nix;
    flatpak = import ./flatpak.nix;
    steam = import ./steam.nix;
    laptop = import ./laptop.nix;

    wonder-devops = {config, lib, pkgs, ... }: {
      nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ];
    };

    ai-agents = {config, lib, pkgs, ... }: {
      nixpkgs.overlays = [
        inputs.ml-pkgs.overlays.apis
        inputs.ml-pkgs.overlays.tools
      ];

      environment.systemPackages = with pkgs; [
        aider-chat
      ];
    };

    ollama = { config, lib, pkgs, ... }: {
      nixpkgs.overlays = [
        (final: prev: let
          unstable = import inputs.nixpkgs-unstable {
            system = prev.system;
          }; in {
            inherit (unstable) ollama ollama-cuda;
          })
      ];

      environment.systemPackages = with pkgs; [
        ollama
      ];
    };

    overlay-wonder-devops = {config, lib, pkgs, ... }: {
      nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ];
    };
  };
}
