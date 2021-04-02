{ config, lib, pkgs, ... }:

let cfg = {
      nic = "eno1";
      uplinkVlanId = 60;
      localVlanId = 90;
    };

    vlanUplink = "vlan.wan";
    vlanLocal = "vlan.lan";

in {
  networking.networkmanager.enable = lib.mkForce false;
  networking.nameservers = [ "8.8.8.8" ];
  
  # Enable Kernel IP Forwarding.
  #
  # For more details, refer to
  # https://unix.stackexchange.com/questions/14056/what-is-kernel-ip-forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.default.forwarding" = true;
    # TODO(breakds): Enable this for ipv6 
    # "net.ipv6.conf.all.forwarding" = true;
    # "net.ipv6.conf.default.forwarding" = true;
  };


  # Create 2 separate VLAN devices for the NIC (e.g. eno1). One of the
  # VLAN device will be used for the uplink, and the other one will be
  # used for the internal network.

  networking.vlans = {
    # uplink
    "${vlanUplink}" = {
      id = cfg.uplinkVlanId;
      interface = cfg.nic;
    };

    # internal
    "${vlanLocal}" = {
      id = cfg.localVlanId;
      interface = cfg.nic;
    };
  };

  networking.interfaces."${cfg.nic}".useDHCP = false;
  # Let the modem "DHCP me" for the uplink VLAN.
  networking.interfaces."${vlanUplink}".useDHCP = true;
  networking.interfaces."${vlanLocal}" = {
    # This is going to be the router's IP to internal devices connects
    # to it.
    ipv4.addresses = [ {
      address = "10.1.1.1";
      prefixLength = 24;  # Subnet Mask = 10.1.1.0/24
    } ];
    useDHCP = false;
  };
}
