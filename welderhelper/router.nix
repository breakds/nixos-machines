{ config, lib, pkgs, ... }:

let cfg = {
      nic = "eno1";
      uplinkVlanId = 60;
      localVlanId = 90;
    };

    vlanUplink = "wan${toString cfg.uplinkVlanId}";
    vlanLocal = "lan${toString cfg.localVlanId}";

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

  # Enable DHCP
  services.dhcpd4 = {
    enable = true;
    interfaces = [ vlanLocal ];
    extraConfig = ''
      option domain-name-servers 1.1.1.1, 8.8.8.8, 8.8.4.4;
      option subnet-mask 255.255.255.0;

      default-lease-time 25920000;
      max-lease-time 25920000;
      
      subnet 10.77.1.0 netmask 255.255.255.0 {
        interface ${vlanLocal};
        range 10.77.1.20 10.77.1.240;
        option routers 10.77.1.1;
        option broadcast-address 10.77.1.255;
      }
    '';
  };

  # NAT (and Firewall)
  #
  # Disable NixOS's stock firewall and NAT (by iptables) and use nftables instead.
  #
  # 1. Life of a packet
  #    * input:       packet received by this machine
  #    * output:      packet originating from this machine leaves it
  #    * foward:      packet that are being routed by this machine
  #    * postrouting: packet after being processed leaves this machine
  # 2. Each chain will have a type
  #    * filter:  allows you to accept or drop packet
  #    * nat:     allows you to modify the source IP information
  networking.firewall.enable = false;
  networking.nat.enable = false;
  networking.nftables = {
    enable = true;
    # TODO(breakds): Add firewall
    ruleset = ''
      define wan = ${vlanUplink}
      define lan = ${vlanLocal}
      # Table for the IPv4 NAT
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority 0
        }
        chain postrouting {
          type nat hook postrouting priority 0
          oifname $wan masquerade
        }
      }
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