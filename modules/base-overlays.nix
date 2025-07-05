{ config, lib, pkgs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      inherit (prev.unstable) n8n glance gemini-cli claude-code;
      shuriken = final.callPackage ../pkgs/shuriken {};
    })
  ];
}
