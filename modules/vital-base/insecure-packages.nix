# Aggregates `nixpkgs.config.permittedInsecurePackages` across modules.
#
# `nixpkgs.config` cannot be set from more than one module: its option type
# (nixos/modules/misc/nixpkgs.nix) merges definitions with `lib.recursiveUpdate`,
# which recurses only while both sides are attrsets and otherwise takes one side
# wholesale. `permittedInsecurePackages` is a list, i.e. a leaf, so a second
# definition silently clobbers the first -- no conflict error, no warning. Only
# `allowUnfreePackages`, `packageOverrides` and `perlPackageOverrides` are
# special-cased upstream to combine.
#
# `vital.insecurePackages` is a plain `listOf str`, which does merge by
# concatenation, so each entry can live next to whatever needs it. This module
# owns the single `nixpkgs.config.permittedInsecurePackages` definition.

{ config, lib, ... }:

{
  options.vital = with lib; {
    insecurePackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "pnpm-9.15.9" ];
      description = ''
        Packages to allow despite being marked insecure, as
        `<pname>-<version>` strings. Declare these next to the module that
        pulls the package in, together with a comment explaining why the
        vulnerability is not reachable and when the entry can be dropped.
      '';
    };
  };

  config = {
    nixpkgs.config.permittedInsecurePackages = config.vital.insecurePackages;
  };
}
