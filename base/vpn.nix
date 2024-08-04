{ config, pkgs, lib, ... }:

let cfg = config.vital.vpn;

in {
  options.vital.vpn = {
    expressvpn = lib.mkEnableOption "Enable expressvpn as a service";
    tailscale = lib.mkEnableOption "Enable the tailscale vpn service";
    clash = lib.mkEnableOption "Enable the clash verge";
  };

  config = lib.mkMerge [
    # Express VPN
    (lib.mkIf cfg.expressvpn {
      # Need the service running
      services.expressvpn.enable = true;

      # Also need the command line tool for interacting such as activate and connect
      environment.systemPackages = with pkgs; [
        expressvpn
      ];
    })

    # tailscale
    (lib.mkIf cfg.tailscale {
      services.tailscale = {
        enable = true;
        port = 41661;  # The default is 41641.
      };

      networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
      networking.firewall.checkReversePath = "loose";


      # Also need the tailscale cli tool
      environment.systemPackages = with pkgs; [ tailscale ];
    })

    # clash
    (lib.mkIf cfg.clash {
      # We do not enable tun mode here for scientific surfing purpose. The tun
      # mode is useful for the actual VPN use case.
      programs.clash-verge.enable = true;
    })
  ];
}
