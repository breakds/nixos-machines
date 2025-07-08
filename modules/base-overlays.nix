# Note that you will need
# `{ specialArgs = { inherit (inputs) nixpkgs-unstable }`
# for you `nixosSystem`.
{ config, lib, pkgs, nixpkgs-unstable, ... }: {
  nixpkgs.overlays = [
    (final: prev: rec {
      unstable = import nixpkgs-unstable {
        inherit (final) system config;
      };
      inherit (unstable) n8n glance gemini-cli claude-code ollama home-assistant-custom-components;
      shuriken = final.callPackage ../pkgs/shuriken {};
    })
  ];
}
