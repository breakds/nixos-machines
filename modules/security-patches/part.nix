{ inputs, ... }:

{
  flake.overlays.security-patches = final: prev: let
    # CVE-2026-111943: reject the compromised eMudhra intermediates.
    # Keep Go private: a global override rebuilds libcap and its dependents.
    # Remove this backport once both nixpkgs pins include the fixed versions.
    patchedGo126 = if prev.lib.versionAtLeast prev.go_1_26.version "1.26.10" then
      prev.go_1_26
    else
      prev.go_1_26.overrideAttrs (_: {
        version = "1.26.10";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go1.26.10.src.tar.gz";
          hash = "sha256-/WPog7ovK/ypPBZGsx6+9j4rHk0rMXyXidl2po2B828=";
        };
      });
    patchedGo127 = if prev.lib.versionAtLeast prev.go_1_27.version "1.27.3" then
      prev.go_1_27
    else
      prev.go_1_27.overrideAttrs (_: {
        version = "1.27.3";
        src = prev.fetchurl {
          url = "https://go.dev/dl/go1.27.3.src.tar.gz";
          hash = "sha256-bndJA1zzYPBrJXXRYup535/ajvZxiJ5cN1+OUHd/Jrs=";
        };
      });
    buildGoModule = prev.buildGoModule.override { go = patchedGo126; };
    buildGo127Module = prev.buildGo127Module.override { go = patchedGo127; };
  in {
    tailscale = if prev.lib.versionAtLeast prev.tailscale.version "1.104.2" then
      prev.tailscale
    else
      final.callPackage ../../nix/pkgs/tailscale/package.nix {
        inherit buildGo127Module;
      };

    # Applications that connect to HTTPS endpoints. Keep this list explicit;
    # build tools and libraries must retain nixpkgs' original Go compiler.
    syncthing = prev.syncthing.override {
      inherit buildGoModule;
      go = patchedGo126;
    };
    lego = prev.lego.override { inherit buildGoModule; };
    oauth2-proxy = prev.oauth2-proxy.override { inherit buildGoModule; };
    glance = prev.glance.override { inherit buildGoModule; };
    grafana = prev.grafana.override { inherit buildGoModule; };
    forgejo-lts = prev.forgejo-lts.override { inherit buildGoModule; };
    prometheus = prev.prometheus.override { inherit buildGoModule; };
    go2rtc = prev.go2rtc.override { inherit buildGoModule; };
    ollama = prev.ollama.override { inherit buildGoModule; };
    ollama-cuda = prev.ollama-cuda.override { inherit buildGoModule; };
    gh = prev.gh.override { inherit buildGoModule; };
    azure-storage-azcopy = prev.azure-storage-azcopy.override {
      inherit buildGoModule;
    };

    # Docker also pulls images through its bundled containerd and CLI plugins.
    docker = prev.docker.override {
      inherit buildGoModule;
      go = patchedGo126;
    };
    containerd = prev.containerd.override { inherit buildGoModule; };
    docker-buildx = prev.docker-buildx.override { inherit buildGoModule; };
    docker-compose = prev.docker-compose.override { inherit buildGoModule; };
    distribution = prev.distribution.override { inherit buildGoModule; };
  };

  flake.nixosModules.security-patches = { pkgs, lib, extendModules, ... }: let
    systemWithoutReplacements = (extendModules {
      modules = [ {
        system.replaceDependencies.replacements = lib.mkForce [ ];
      } ];
    }).config.system.build.toplevel;
    systemClosure = pkgs.closureInfo {
      rootPaths = [ systemWithoutReplacements ];
    };
    systemPaths = lib.splitString "\n"
      (builtins.readFile "${systemClosure}/store-paths");
  in {
    nixpkgs.overlays = [ inputs.self.overlays.security-patches ];

    # CVE-2026-111497: replace the shared decoder without rebuilding curl's
    # entire dependency tree. Covers Node and Python, including unstable/32-bit.
    # Remove once both nixpkgs pins supply Brotli 1.2.1 or newer. Bundled/static
    # copies need their own updates; this only replaces shared libraries.
    # Keep the normal priority explicit so mkForce [] skips the closure lookup.
    system.replaceDependencies.replacements = lib.mkOverride
      lib.modules.defaultOverridePriority (map
        (brotli: {
          oldDependency = lib.getLib brotli;
          newDependency = lib.getLib (brotli.overrideAttrs (_: {
            version = "1.2.1";
            src = pkgs.fetchFromGitHub {
              owner = "google";
              repo = "brotli";
              tag = "v1.2.1";
              hash = "sha256-llY72cYffDv0ugsH0p89xIPEbElV4L8u7U/Fe8hT3gI=";
            };
          }));
        })
        (lib.filter (brotli:
          lib.versionOlder brotli.version "1.2.1"
          && lib.elem (toString (lib.getLib brotli)) systemPaths)
          (lib.unique ([ pkgs.brotli ]
            ++ lib.optional (pkgs ? unstable) pkgs.unstable.brotli
            ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64
              ([ pkgs.pkgsi686Linux.brotli ]
                ++ lib.optional (pkgs ? unstable) pkgs.unstable.pkgsi686Linux.brotli)))));
  };
}
