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

    overlay-wonder-devops = {config, lib, pkgs, ... }: {
      nixpkgs.overlays = [ inputs.wonder-devops.overlays.default ];
    };
  };
}
