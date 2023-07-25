{
  description = "Environment to test the tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    overlays.dev = nixpkgs.lib.composeManyExtensions [
    ];
  } // inputs.utils.lib.eachSystem [
    "x86_64-linux"
  ] (system:
    let pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.dev ];
        };
    in {
      devShells.default = let
        python-env = pkgs.python3.withPackages (pyPkgs: with pyPkgs; [
          wandb
          click
          loguru
          lark
        ]);

        name = "shuriken";
      in pkgs.mkShell {
        inherit name;

        packages = [
          python-env
        ];

        shellHooks = let pythonIcon = "f3e2"; in ''
          export PS1="$(echo -e '\u${pythonIcon}') {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} (${name}) \\$ \[$(tput sgr0)\]"
        '';
      };
    });
}
