{ config, lib, pkgs, ... }:

{
  config = {
    systemd.services.medea-clipper = {
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.medea-clipper
        pkgs.xclip
      ];

      serviceConfig = {
        Type = "simple";
        User = "breakds";
        Group = "breakds";
        ExecStart = "${pkgs.medea-clipper}/bin/app serve --port=33377";
        Restart = "always";
      };
    };
    networking.firewall.allowedTCPPorts = [ 33377 ];
  };
}
