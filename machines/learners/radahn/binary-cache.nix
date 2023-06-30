{ config, lib, pkgs, ... }:

let stateDir = "/var/lib/binary-cache/state";

in {
  config = {
    systemd.tmpfiles.rules = [
      "d ${stateDir} 775 root root -"
      "d ${stateDir}/secret 775 root root -"
    ];

    systemd.services.nix-serve-manual-setup = {
      description = "Create Keys for Nix Serve";
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      wantedBy = [ "multi-user.target" ];
      script = ''
      if [ ! -e ${stateDir}/secret/initialized ]; then
        # create signing keys
        /run/current-system/sw/bin/install -d -m 551 ${stateDir}/secret/binary-cache.radahn-1
        /run/current-system/sw/bin/nix-store --generate-binary-cache-key \
            binary-cache.radahn-1 \
            ${stateDir}/secret/binary-cache.radahn-1/secret \
            ${stateDir}/secret/binary-cache.radahn-1/public
        /run/current-system/sw/bin/chmod 440 ${stateDir}/secret/binary-cache.radahn-1/secret
        /run/current-system/sw/bin/chmod 444 ${stateDir}/secret/binary-cache.radahn-1/public
        # done
        touch ${stateDir}/secret/initialized
      fi
    '';
    };

    services.nix-serve = {
      enable = true;
      openFirewall = true;
      port = 17777;
      secretKeyFile = "${stateDir}/secret/binary-cache.radahn-1/secret";
    };
  };
}
