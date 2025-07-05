final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # Nov 18 2022
      url = https://github.com/NixOS/nixpkgs/tarball/42a1c966be226125b48c384171c44c651c236c22;
      sha256 = "082dpl311xlspwm5l3h2hf10ww6l59m7k2g2hdrqs4kwwsj9x6mf";
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
  inherit (unstablePkgs) n8n glance;
  
  shuriken = final.callPackage ../../pkgs/shuriken {};
}
