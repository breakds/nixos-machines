final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # Nov 18 2022
      url = https://github.com/NixOS/nixpkgs/tarball/a04a4bbbeb5476687a5a1444a187c4b2877233ed;
      sha256 = "1n8sb8a0bv9lg4rihpg9df5x55zq3baqc9055n3jydakncca374f";
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
  newLinuxPackages_6_0 = unstablePkgs.linuxPackages_6_0;
}
