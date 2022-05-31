final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # 2022 Apr 21
      url = https://github.com/NixOS/nixpkgs/tarball/bfb6f709c032169ea6fa20e2c4c8741a06d5e018;
      sha256 = "0r8s252lzn9lyg1k45khmw92z325gnswbdm6klq3ch0i66p8nnx6";
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
