final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # 2021 Sep 06
      url = https://github.com/NixOS/nixpkgs/tarball/4f0bc6d71d1fbabf6e1684035290b65893982da5;
      sha256 = "1hdz8y0za2wl0693p4gnm36kgsv2wmjshq0p204f34pb5b9bdq0d";
    }) {
      config.allowUnfree = true;
      system = prev.system;
    };

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

  tensorboard26 = unstablePkgs.python3Packages.tensorflow-tensorboard;

  ethminer = final.callPackage ../../pkgs/temp/ethminer { cudaSupport = true; };
  shuriken = final.callPackage ../../pkgs/shuriken {};
}
