final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # 2021 Jan 03
      url = https://github.com/NixOS/nixpkgs/tarball/77d190f10931c1d06d87bf6d772bf65346c71777;
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

  # TODO(breakds): Upgrade this to cuda 11 and make pytorch work.
  cudatoolkit = final.cudatoolkit_11;

  # TODO(breakds): Add www.breakds.org

  # TODO(breakds): add texlive

  terraria-server = unstablePkgs.terraria-server;

  ethminer = final.callPackage ../../pkgs/ethminer {};
}
