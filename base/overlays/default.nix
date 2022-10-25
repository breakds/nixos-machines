final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # Oct 20 2022
      url = https://github.com/NixOS/nixpkgs/tarball/9a22f2470f21e3320128e50265a8962229da5a85;
      sha256 = "0iaay9294ar40nnrdi6aya13yr65qjwmy8cmisdraw0rb8m6ww84";
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
  medea-clipper = final.python3Packages.callPackage ../../pkgs/medea-clipper {};
  # TODO(breakds): Remove this when upgraded to 22.11. Currently we
  # need 520.56.06 nvidia driver for the RTX 4090.
  newNvidiaDrivers = unstablePkgs.linuxPackages.nvidiaPackages;
  newLinuxPackages = unstablePkgs.linuxPackages;
}
