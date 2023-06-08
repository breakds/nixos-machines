# This is refactored based on Greg-L's
# https://github.com/Gerg-L/nixos/blob/master/modules/builders.nix

{ config, pkgs, lib, ... }:

let cfg = config.vital.distributed-build;

    builder-registry = import ../data/builder-registry.nix;

    mkBuilder = registryItem: {
      hostName = registryItem.hostName;
      protocol = "ssh-ng";
      maxJobs = registryItem.maxJobs;
      speedFactor = registryItem.speedFactor;
      systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
      sshUser = "nixbuilder";
      sshKey = "/home/breakds/.ssh/nixbuilder_malenia";
      # No publicHostKey specified. Use the local machine's own known hosts.
    };

in {
  # Just in case you want to add localhost as one of the build
  # machines as well, put the following code in your configuration
  #
  # nix.buildMachines = {
  #   hostName = "localhost";
  #   systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
  #   maxJobs = lib.mkDefault 12;
  #   speedFactor = lib.mkDefault 2;
  #   supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
  # }
  #
  # You will need to decide the max jobs and speed factor.

  options.vital.distributed-build = {
    enable = lib.mkEnableOption "Enable using build machines for distributed Nix build";

    location = lib.mkOption {
      type = lib.types.enum [ "homelab" "lab" ];
      default = "homelab";
      description = ''
        Where the machine is located. It will only use the builders in the same
        location for distributed build.
      '';
    };
    # TODO: enableSelf
  };

  config = lib.mkMerge [
    # Add build machines if distributed build is enabled.
    (lib.mkIf cfg.enable {
      nix = {
        distributedBuilds = true;
        buildMachines = let
          items = builtins.filter (x: cfg.location == x.location)
            (lib.attrsets.attrValues builder-registry);
        in builtins.map mkBuilder items;

        settings = {
          trusted-substituters = [
            "ssh://octavian.local"
            "ssh://malenia.local"
            "ssh://gail3"
            "ssh://radahn"
            "ssh://samaritan"
          ];
        };
      };
    })

    (lib.mkIf (builtins.hasAttr config.networking.hostName builder-registry) {
      users = {
        groups.nixbuilder = {};
        users.nixbuilder = {
          createHome = false;
          isSystemUser = true;
          openssh.authorizedKeys.keyFiles = [
            ../data/keys/breakds_samaritan.pub
            ../data/keys/nixbuilder_malenia.pub
          ];
          useDefaultShell = true;
          group = "nixbuilder";
        };
      };

      nix.settings = {
        trusted-users = [ "nixbuilder" ];
        keep-outputs = true;
        keep-derivations = true;
        auto-optimise-store = true;
      };
    })
  ];
}
