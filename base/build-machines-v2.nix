{ config, pkgs, lib, ... }:

let cfg = config.vital.distributed-build;

    builder-registry = import ../data/builder-registry.nix;
    cache-registry = import ../data/cache-registry-v2.nix;

    selectedCaches = builtins.map (name: cache-registry.${name}) cfg.caches;
    selectedBuilders = builtins.map (name: builder-registry.${name}) cfg.builders;

in {
  options.vital.distributed-build = with lib; {
    caches = mkOption {
      type = types.listOf (types.enum (builtins.attrNames cache-registry));
      default = [];
      description = ''
        Specifies the list of binary caches to use.
      '';
    };

    builders = mkOption {
      type = types.listOf (types.enum (builtins.attrNames builder-registry));
      default = [];
      description = ''
        Specifies the list of remote builders.
      '';
    };
  };

  config = lib.mkMerge [
    ({
      nix.settings = {
        substituters = builtins.map (x: x.url) selectedCaches ++ [
          "https://cache.nixos.org"
        ];
        trusted-public-keys = builtins.map (x: x.publicKey) selectedCaches;
      };
    })

    (lib.mkIf ((builtins.length selectedBuilders) > 0) {
      nix = {
        distributedBuilds = true;
        buildMachines = builtins.map (x: {
          inherit (x) hostName maxJobs speedFactor;
          systems = [ "x86_64-linux" "aarch64-linux" ];
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
          sshUser = if builtins.hasAttr "sshUser" x then x.sshUser else "nixbuilder";
        }) selectedBuilders;
      };
    })
  ];
}
