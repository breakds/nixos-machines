{ config, pkgs, lib, ... }:

let nodejs-14_x = (import (builtins.fetchGit {
      name = "nixpkgs-nodejs-14.21.3";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "9957cd48326fe8dbd52fdc50dd2502307f188b0d";
    }) {}).nodejs-14_x;

in {
  nixpkgs.overlays = [
    (finale: prev: {
      nodejs-14_x = nodejs-14_x;
    })
  ];
}
