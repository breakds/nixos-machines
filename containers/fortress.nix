# Courtesy of
#
# 1. IOHK: https://github.com/input-output-hk/ci-ops/blob/2587a1a807ecd19dd33b69557f9c6b33c15b509c/modules/hydra-master-main.nix
#
# 2. KJ Orbekk: https://git.orbekk.com/nixos-config.git/tree/config/hydra.nix

{ config, lib, pkgs, ... }:

{
  imports = [
    ../base/container.nix
  ];

  config = {
    networking = {
      hostName = "fortress";
    };

    nixpkgs.config = {
      allowUnfree = true;
    };

    nix = {
      distributedBuilds = true;

      # Not totally sure I understand this but I am setting it to be
      # greater than the number of maxJobs below.
      nrBuildUsers = 64;

      # Enable this if I run low on disk.
      gc.automatic = lib.mkForce false;

      buildMachines = [
        {
          hostName = "localhost";
          systems = [ "x86_64-linux" "i686-linux" ];
          # Richelieu have 32 cores so consuming 24 cores is good.
          maxJobs = 24;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
      ];

      # This helps reduces the disk footprint of /nix/store.
      autoOptimiseStore = true;
    };

    # This is to create nix store key pairs that Hydra can use to sign the built
    # packages. To be more specific, the packages that Hydra builds will be
    # signed by the private key, and the user of those packages (presumably via
    # a binary cache) is supposed to use the public key to verify that the
    # packages are built by this hydra instance.
    systemd.services.hydra-key-pair-setup = {
      description = "Create Keys for Hydra";

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        path = config.systemd.services.hydra-init.environment.PATH;
      };

      wantedBy = [ "multi-user.target" ];
      requires = [ "hydra-init.service" ];
      after = [ "hydra-init.service" ];

      # Inherit the environment variables from hydra-init, except for its PATH
      # (not necessarily, but removing PATH makes our PATH cleaner here).
      environment = builtins.removeAttrs config.systemd.services.hydra-init.environment ["PATH"];

      script = let
        keyRoot = "/opt/keys/hydra";
        hostname = "hydra.breakds.org";
        keyDirectory = "${keyRoot}/${hostname}-1";
      in ''
        if [ ! -e ~hydra/.setup-is-complete ]; then
          # Create the directory to hold the keys with mode 551
          /run/current-system/sw/bin/install -d -m 551 ${keyDirectory}
          # Now actually generate the pair of keys (private + public)
          /run/current-system/sw/bin/nix-store --generate-binary-cache-key \
             ${hostname}-1 ${keyDirectory}/secret ${keyDirectory}/public

          # Set correct access permissions
          /run/current-system/sw/bin/chown -R hydra:hydra ${keyRoot}
          /run/current-system/sw/bin/chmod 440 ${keyDirectory}/secret
          # Note that the others should be able to see the public key
          /run/current-system/sw/bin/chmod 444 ${keyDirectory}/public

          # done
          touch ~hydra/.setup-is-complete
        fi
      '';
    };


    # Give evaluator 32 Gigabytes of memory
    systemd.services.hydra-evaluator.environment.GC_INITIAL_HEAP_SIZE = toString (1024*1024*1024*32);

    services.hydra = {
      enable = true;
      useSubstitutes = true;
      notificationSender = "breakds+hydra@gmail.com";
      port = 8080;
      buildMachinesFiles = [];
      
      hydraURL = "https://hydra.breakds.org";
      # NOTE(breakds): Enable upload_logs_to_binary_cache if needed.
      # NOTE(breakds): Enable server_store_uri when needed
      # TODO(breakds): Update store-uri with options
      extraConfig = ''
        # I think this means 16GB, which should be good
        evaluator_max_memory_size = 16384
        max_concurrent_evals = 12
        store_uri = file:///nix/store?secret-key=/opt/keys/hydra/hydra.breakds.org-1/secret
        # server_store_uri = https://cache.breakds.org
        # binary_cache_public_uri = https://cache.breakds.org
        log_prefix = https://hydra.breakds.org
        # upload_logs_to_binary_cache = true
      '';

      # logo = ./hydra/iohk-logo.png;
    };


    networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
