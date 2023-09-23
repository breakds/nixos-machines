{ lib, pkgs, ... }:

let sysConfig = (import <nixpkgs/nixos> {}).config;

in {
  programs.git = {
    enable = true;
    package = lib.mkDefault pkgs.gitAndTools.gitFull;
    userName = lib.mkDefault "Break Yang";
    userEmail = lib.mkDefault "yiqing.yang@horizon.com";

    difftastic = {
      enable = true;
    };

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      advice.addIgnoredFile = false;
    };
  };
}
