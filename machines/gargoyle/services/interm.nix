{ config, lib, pkgs, ... }:

let port = (import ../../../data/service-registry.nix).interm.port;

in {
  config = {
    systemd.services.interm = {
      description = "Interface + Terminal";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [];

      serviceConfig = {
        ExecStart = "${pkgs.python3Packages.interm}/bin/interm";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart= "on-failure";
        RestartSec = "1s";
      };

      environment = {
        INTERM_APP_DIST_DIR = "${pkgs.interm-webui}";
        INTERM_PORT = "${toString port}";
      };
    };
  };
}
