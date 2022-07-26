final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # June 10 2022
      url = https://github.com/NixOS/nixpkgs/tarball/0207d018f626f0907f966f232f821ddd8ce054d4;
      sha256 = "1k4w5sd6kh7lr2gm1jccvv2kmg0n9nssx7hic2n6pgiwc2cppi5r";
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
  ethminer = final.callPackage ../../pkgs/temp/ethminer { cudaSupport = true; };
  shuriken = final.callPackage ../../pkgs/shuriken {};
}
