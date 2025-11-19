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

        # Here, we add all the keys instead of only the selected caches, so that
        # in case we want to manually add a substituter in the command line, we
        # can do that.
        trusted-public-keys = lib.attrsets.mapAttrsToList (
          host: properties: properties.publicKey) cache-registry;

        trusted-users = [ "root" "breakds" ];
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
        extraOptions = ''
          builders-use-substitutes = true
        '';
      };
    })

    # If the machine is a builder (the hostname is in the builder reigstry),
    # prepare it as a builder by tuning some of the nix settings.
    (lib.mkIf (builtins.hasAttr config.networking.hostName builder-registry) {
      users = {
        groups.nixbuilder = {};
        users.nixbuilder = {
          createHome = false;
          isSystemUser = true;
          openssh.authorizedKeys.keyFiles = [
            ../data/keys/breakds_samaritan.pub
            ../data/keys/breakds_malenia.pub
            ../data/keys/nixbuilder_malenia.pub
          ];
          useDefaultShell = true;
          group = "nixbuilder";
        };
      };

      nix.settings = {
        trusted-users = [ "nixbuilder" "breakds" "root" ];
        keep-outputs = true;
        keep-derivations = true;
        auto-optimise-store = true;
      };
    })
  ];
}
