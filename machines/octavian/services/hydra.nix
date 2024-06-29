# Credit to KJ Orbekk: https://git.orbekk.com/nixos-config.git/tree/config/hydra.nix
#
# Notes:
#
# 1. In order to have hydra run jobs accessing private github repo,
#    you will need to setup the ssh keys for the user "hydra". Seems
#    that they should be put on /var/lib/hydra/.ssh
#
# 2. By default the user hydra does not have password so that you
#    cannot login. You will need to set the password.
#
# 3. After login with hydra, run
#         hydra-create-user breakds --password-prompt --role admin
#    to create an account. You have to do this with user "hydra"

{ config, lib, pkgs, ... }:
let hydraInfo = (import ../../../data/service-registry.nix).hydra;
    stateDir = "/var/lib/hydra/state";
    serveInfo = (import ../../../data/service-registry.nix).nix-serve;

in {
  services.hydra = {
    enable = true;
    hydraURL = "https://${hydraInfo.domain}";
    notificationSender = "bds+hydra@breakds.org";
    buildMachinesFiles = [];
    useSubstitutes = true;
    port = hydraInfo.port;
    extraConfig = ''
      store-uri = file:///nix/store?secret-key=/opt/secret/hydra_key/hydra.breakds.org-1/secret
    '';
  };

  networking.firewall.allowedTCPPorts = [ hydraInfo.port ];

  # From https://github.com/input-output-hk/iohk-nixops
  systemd.services.hydra-manual-setup = {
    description = "Create Keys for Hydra";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "hydra-init.service" ];
    after = [ "hydra-init.service" ];
    environment = lib.mkForce config.systemd.services.hydra-init.environment;
    script = ''
      if [ ! -e ${stateDir}/secret/hydra_key/initialized ]; then
        # create signing keys
        /run/current-system/sw/bin/install -d -m 551 ${stateDir}/secret/hydra_key/hydra.breakds.org-1
        /run/current-system/sw/bin/nix-store --generate-binary-cache-key \
            hydra.breakds.org-1 \
            ${stateDir}/secret/hydra_key/hydra.breakds.org-1/secret \
            ${stateDir}/secret/hydra_key/hydra.breakds.org-1/public
        /run/current-system/sw/bin/chown -R hydra:hydra ${stateDir}/secret/hydra_key
        /run/current-system/sw/bin/chmod 440 ${stateDir}/secret/hydra_key/hydra.breakds.org-1/secret
        /run/current-system/sw/bin/chmod 444 ${stateDir}/secret/hydra_key/hydra.breakds.org-1/public
        # done
        touch ${stateDir}/secret/hydra_key/initialized
      fi
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 775 hydra hydra -"
    "d ${stateDir}/secret 775 hydra hydra -"
    "d ${stateDir}/secret/hydra_key 775 hydra hydra -"
  ];

  services.nginx = {
    virtualHosts = {
      "${hydraInfo.domain}" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString hydraInfo.port}";
          proxyWebsockets = true;
        };
      };
    };
  };

  services.nix-serve = {
    enable = true;
    openFirewall = true;
    port = serveInfo.port;
    secretKeyFile = "${stateDir}/secret/hydra_key/hydra.breakds.org-1/secret";
  };

  nix = {
    distributedBuilds = true;
    nrBuildUsers = 30;
    # Enable this if I run low on disk.
    gc.automatic = lib.mkForce true;
    buildMachines = [{
      hostName = "localhost";
      systems = [ "x86_64-linux" "i686-linux" "aarch64" ];
      maxJobs = 24;
      speedFactor = 4;
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    }];
    extraOptions = ''
      allowed-uris = https://
    '';
  };
  nixpkgs.config = { allowUnfree = true; };
}
