{ config, pkgs, ... }:

let commonLispEnv = pkgs.sbcl.withPackages (ps: with ps; [
      cl-ppcre
    ]);

in {
  environment.systemPackages = with pkgs; [
    commonLispEnv
  ];
}
