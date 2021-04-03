{ config, lib, pkgs, ... }:

let cfg = {
      nic = "eno1";
      uplinkVlanId = 60;
      localVlanId = 90;
    };

    vlanUplink = "wan.${toString cfg.uplinkVlanId}";
    vlanLocal = "lan.${toString cfg.localVlanId}";

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

  # Dnsmasq
  #
  # Network infrastructure: DNS server and DHCP server
  services.dnsmasq = {
    enable = true;
    servers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];
    # Detailed Explanations
    # ---------------------
    # Example: https://thekelleys.org.uk/gitweb/?p=dnsmasq.git;a=blob;f=dnsmasq.conf.example;hb=HEAD#l333
    #
    # 1. `dhcp-authoritative` - Quote: Dnsmasq barges in and takes over the lease for any client to
    #    broadcast on the network, whether it has a record of the lease or not. This avoids long
    #    timeouts when a machine wakes up on a new network.
    #
    # 2. `dhcp-option=option:<option-name>,<option-value>` set options with key value pairs.
    #
    # 3. `interface=<interface>` restrict which network Dnsmasq listens to
    #
    # 4. `port=0` disables DNS part of Dnsmasq.
    #
    # 5. `dhcp-option=option:router,<ip>` overrides the default router/gateway passed down to
    #    tenant. The default assumes the router is the same machine as the one running dnsmasq.
    #
    # 6. `dhcp-option=option:netmask,<ip>` tells the tenant the subnet mask to use.
    #
    # 7. `dhcp-range=<ip-start>:<ip-end>:<lease-time>` specifies the IP allocation range and lease
    #    time for the tenants.
    extraConfig = ''
      port=0
      dhcp-authoritative
      dhcp-option=option:router,10.77.1.1
      dhcp-option=option:dns-server,1.1.1.1,8.8.8.8,8.8.4.4
      dhcp-option=option:netmask,255.255.255.0
      dhcp-range=10.77.1.20,10.77.1.240,24h
    '';
  };

  # Topology for the managed switch:
  #
  #
  #
  #  +-----+-----+-----+
  #  |  A  |  B  |  C  | <- managed switch
  #  |     |     |     |
  #  +--|--+--|--+--|--+  
  #     |     |     +------------------ Wifi AP/Devices
  #     |     |
  #     |     +------------ Modem
  #   router
  #
  # If the vlan ID for wan is 60, and the vlan ID for lan is 90, we
  # need to configure
  #
  # 1. A as a Trunk Port that allows 60 and 90
  # 2. B as an Access (Untagged) Port with Vlan ID (and PVID) = 60
  # 3. C as an Access (Untagged) Port with Vlan ID (and PVID) = 90
  networking.interfaces."${cfg.nic}".useDHCP = false;
  # Let the modem "DHCP me" for the uplink VLAN.
  networking.interfaces."${vlanUplink}".useDHCP = true;
  networking.interfaces."${vlanLocal}" = {
    # This is going to be the router's IP to internal devices connects
    # to it.
    ipv4.addresses = [ {
      address = "10.77.1.1";
      prefixLength = 24;  # Subnet Mask = 10.1.1.0/24
    } ];
    useDHCP = false;
  };
}
