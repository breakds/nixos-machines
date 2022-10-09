{
  description = "Clipboard for medea the media center";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.05";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
    ] (system:
      let pkgs = import nixpkgs {
            inherit system;
          };
      in {
        devShell = pkgs.mkShell rec {
          name = "medea-clipper";
          packages = with pkgs; [ poetry pyright ];
          shellHook = ''
            export PS1="$(echo -e '\uf3e2') {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} (${name}) \\$ \[$(tput sgr0)\]"
            export PYTHONPATH="$(pwd):$PYTHONPATH"
            export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib/:${pkgs.zlib}/lib/:$LD_LIBRARY_PATH"
          '';
        };
      });
}
