final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # 2021 Jun 22
      url = https://github.com/NixOS/nixpkgs/tarball/bb8c2116dd2d03775c96e0695bfbace7074308b4;
      sha256 = "152hy6vzwv0nvg38lx1ngdqnqihspg518la6br38pxihl6rfbnp2";
    }) { config.allowUnfree = true; };

    pythonOverride = {
      pacakgeOverrides = python-final: python-prev: {
        # Put the customized python packages, with or without
        # python-final.callPackage
      };
    };

in {
  # Use llvm 11
  llvmPackages = prev.llvmPackages_11;

  cudatoolkit = final.cudatoolkit_11;

  # TODO(breakds): Add www.breakds.org

  terraria-server = unstablePkgs.terraria-server;

  ethminer = final.callPackage ../../pkgs/ethminer { cudaSupport = true; };
  shuriken = final.callPackage ../../pkgs/shuriken {};  
}
