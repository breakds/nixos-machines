{ config, lib, pkgs, ... }:

{
  config = {
    systemd.services.medea-clipper = {
      wantedBy = [ "multi-user.target" ];

      path = [
        "${pkgs.xclip}/bin"
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.medea-clipper}/bin/app serve --port=33337";
        Restart = "always";
      };
    };
    networking.firewall.allowedTCPPorts = [ 33337 ];
  };
}
