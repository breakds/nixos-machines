{ pkgs, ... }:

let
  iventoy = pkgs.callPackage ../../../pkgs/iventoy { };
in {
  environment.systemPackages = [ iventoy ];

  systemd.services.iventoy = {
    description = "iVentoy ISO network boot server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    # Start only the management UI. Configure ExternalNet DHCP mode there
    # before starting PXE; Kea on Pyrechomper supplies all boot information.
    serviceConfig = {
      Type = "forking";
      PIDFile = "/run/iventoy.pid";
      StateDirectory = "iventoy";
      StateDirectoryMode = "0750";
      PrivateMounts = true;
      ExecStart = "${iventoy}/bin/iventoy /var/lib/iventoy start";
      ExecStop = "${iventoy}/bin/iventoy /var/lib/iventoy stop";
      Restart = "on-failure";
      TimeoutStartSec = 30;
      TimeoutStopSec = 30;
    };
  };

  # Default iVentoy file-serving ports, accessible through the home uplink.
  # ExternalNet mode needs no DHCP or proxy DHCP listener on Octavian.
  networking.firewall.interfaces.enp4s0f0 = {
    allowedTCPPorts = [ 26000 16000 10809 3260 12049 10445 ];
    allowedUDPPorts = [ 69 ];
  };
}
