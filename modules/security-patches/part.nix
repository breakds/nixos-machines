{ inputs, ... }:

{
  flake.overlays.security-patches = final: prev: {
    # CVE-2026-111943: reject the compromised eMudhra intermediates.
    # Remove each backport once both nixpkgs pins include the fixed version.
    go_1_26 = if prev.lib.versionAtLeast prev.go_1_26.version "1.26.10" then
      prev.go_1_26
    else
      prev.go_1_26.overrideAttrs (_: {
        version = "1.26.10";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go1.26.10.src.tar.gz";
          hash = "sha256-/WPog7ovK/ypPBZGsx6+9j4rHk0rMXyXidl2po2B828=";
        };
      });
    go_1_27 = if prev.lib.versionAtLeast prev.go_1_27.version "1.27.3" then
      prev.go_1_27
    else
      prev.go_1_27.overrideAttrs (_: {
        version = "1.27.3";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go1.27.3.src.tar.gz";
          hash = "sha256-bndJA1zzYPBrJXXRYup535/ajvZxiJ5cN1+OUHd/Jrs=";
        };
      });
    tailscale = if prev.lib.versionAtLeast prev.tailscale.version "1.104.2" then
      prev.tailscale
    else
      final.callPackage ../../nix/pkgs/tailscale/package.nix { };
  };

  flake.nixosModules.security-patches = {
    nixpkgs.overlays = [ inputs.self.overlays.security-patches ];
  };
}
