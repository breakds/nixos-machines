{ config, lib, pkgs, ... }:

# Declarative OpenVPN tunnels, each sealed inside its own NixOS container.
#
# A VPN rewrites a routing table, and a routing table belongs to a machine
# rather than to a user. Holding a corporate tunnel directly on a multi-user
# host therefore hands every account on that host a path into the remote
# network the moment the tunnel comes up -- something that can only be walked
# back afterwards with per-UID firewall rules.
#
# Giving each tunnel its own network namespace removes the problem instead of
# policing it. This host's routing table never changes, and no account outside
# the container can see the tunnel at all.
#
# A container runs exactly two things: the tunnel, and an sshd whose single
# account exists only to be proxied through. Other machines reach the remote
# network by using the container as an SSH jump host, and never join the VPN
# themselves:
#
#     ssh -J tunnel@<this-host>:<port> someone@<host-inside-the-vpn>
#
# Requires agenix: an .ovpn profile carries its own private key inline.

let
  cfg = config.vital.vpn.tunnels;

  # The only account inside a tunnel container. It owns nothing and runs
  # nothing -- sshd opens forwarded connections on its behalf.
  tunnelUser = "tunnel";
  tunnelUid = 1001;

  # Every tunnel gets a point-to-point link of its own rather than sharing a
  # bridge, so that containers cannot reach one another.
  hostIp = index: "10.231.${toString index}.1";
  guestIp = index: "10.231.${toString index}.2";

  # agenix decrypts the profile straight into this directory rather than its
  # usual home. `age.secretsDir` holds symlinks into a per-generation
  # directory, and a bind mount needs a real file -- hence `symlink = false`.
  # The container mounts the directory rather than the file itself, so that a
  # re-decrypted profile is still visible to a container already running.
  hostProfileDir = tunnel: "/run/vpn-tunnel-${tunnel.name}";
  guestProfileDir = "/etc/vpn-tunnel";
  profileFile = "profile.ovpn";

  agenixTunnels = lib.filter (tunnel: tunnel.ovpnFile != null) cfg;

  tunnelType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        example = "machine-sp";
        description = ''
          Name of this tunnel, used for its container, its secret and its
          state directory.

          At most 11 characters and no underscores, because the host side of
          the container's virtual link is named after it and interface names
          are limited to 15. Both rules are enforced upstream, in
          nixos-containers.
        '';
      };

      # Exactly one of `ovpnFile` and `ovpnPath` must be set. Which one is a
      # judgement about where the profile is allowed to live, so the module
      # takes no side.
      ovpnFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "../../secrets/vpn-machine-sp.age";
        description = ''
          The agenix-encrypted .ovpn profile, private key and all, kept in the
          repository and decrypted only at runtime.

          Encrypted at rest is not the same as fit to publish. In a public
          repository this commits someone's VPN credentials to a permanent,
          widely mirrored history, where they rely on age holding up
          indefinitely and on every recipient key staying uncompromised. For
          a profile belonging to an employer rather than to you, prefer
          `ovpnPath`.
        '';
      };

      ovpnPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/var/lib/vpn-tunnels/machine-sp.ovpn";
        description = ''
          Absolute path to a profile placed on this host out of band, and
          deliberately never committed. Should be `0400` and owned by root.

          Less declarative than `ovpnFile` -- the file has to be restored by
          hand when the machine is rebuilt -- but it keeps a credential out
          of the repository's history entirely.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        example = 2222;
        description = ''
          Port on this host that reaches the container's sshd.

          Deliberately explicit rather than derived from position in the
          list: remote machines name this port in their ssh config, so
          reordering the list must not silently move it.
        '';
      };

      authorizedKeyFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        example = lib.literalExpression "[ ../../data/keys/sweetango.pub ]";
        description = ''
          Public keys permitted to jump through this tunnel. This is the only
          way in, so it is the entire access control list -- keep it to the
          machines that genuinely need the remote network.
        '';
      };
    };
  };

  mkContainer = index: tunnel: {
    name = tunnel.name;
    value = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostIp index;
      localAddress = guestIp index;

      # Grants NET_ADMIN and /dev/net/tun, without which the tunnel cannot
      # create its interface.
      enableTun = true;

      # Rebuilding this host would otherwise restart the container, dropping
      # the tunnel and every session running through it. Restart it
      # deliberately instead:
      #   systemctl restart container@${tunnel.name}
      restartIfChanged = false;

      forwardPorts = [{
        protocol = "tcp";
        hostPort = tunnel.port;
        containerPort = 22;
      }];

      # For an agenix profile the whole directory is mounted, so that a
      # re-decrypted file -- a new inode -- is still seen by a container that
      # is already running. An out-of-band profile is not replaced underneath
      # us, so the file itself is enough.
      bindMounts.profile = if tunnel.ovpnFile != null
        then { hostPath = hostProfileDir tunnel;
               mountPoint = guestProfileDir;
               isReadOnly = true; }
        else { hostPath = tunnel.ovpnPath;
               mountPoint = "${guestProfileDir}/${profileFile}";
               isReadOnly = true; };

      config = { ... }: {
        system.stateVersion = config.system.stateVersion;
        nixpkgs.pkgs = pkgs;

        networking = {
          defaultGateway = hostIp index;

          # Deliberately none. Everything worth reaching through a tunnel is
          # addressed numerically here, and a container that cannot resolve
          # names is one that cannot be talked into fetching things. A profile
          # whose `remote` is a hostname rather than an address would need
          # this relaxed.
          nameservers = [ ];

          firewall.extraCommands = ''
            # The host is this container's gateway, but nothing in here has
            # any business addressing the host itself -- least of all its
            # sshd, which would turn the jump account into a way back out
            # onto the home network. Traffic *through* the gateway is
            # unaffected: those packets carry their real destination.
            iptables -A OUTPUT -d ${hostIp index} \
              -j REJECT --reject-with icmp-admin-prohibited
          '';
        };

        services.openvpn.servers.tunnel = {
          autoStart = true;
          updateResolvConf = false;
          config = ''
            config ${guestProfileDir}/${profileFile}

            # Send this container's default route into the tunnel. On a shared
            # host that is the thing to avoid; in here it is the entire point.
            # OpenVPN keeps its own host route to the VPN server over the
            # original gateway, so once the tunnel is up the only places this
            # container can reach are the remote network and that one server.
            # Nothing else has to be enumerated, and no firewall rule has to
            # know what the remote network's addresses are.
            redirect-gateway def1
          '';
        };

        users.users.${tunnelUser} = {
          isNormalUser = true;
          uid = tunnelUid;
          openssh.authorizedKeys.keyFiles = tunnel.authorizedKeyFiles;
        };

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
            X11Forwarding = false;
            AllowUsers = [ tunnelUser ];
          };

          # Written out rather than set through `settings`, which only
          # declares the better-known directives.
          extraConfig = ''
            AllowTcpForwarding yes
            AllowAgentForwarding no
            PermitTTY no

            # Restricts jumps to SSH. Wider access is unnecessary: a port
            # forward to a service inside the remote network still works,
            # because it is set up by the inner ssh, not this one.
            PermitOpen *:22

            # Only fires when a session channel is requested, which ProxyJump
            # never does -- so this refuses interactive logins without
            # affecting the jump.
            ForceCommand echo 'This account exists only to be jumped through.'; exit 1
          '';
        };
      };
    };
  };

in {
  options.vital.vpn.tunnels = lib.mkOption {
    type = lib.types.listOf tunnelType;
    default = [ ];
    description = ''
      OpenVPN tunnels this host holds on behalf of other machines, each in a
      container of its own. This host does not forward, route or NAT for
      anyone else, and does not itself join any of them.
    '';
    example = lib.literalExpression ''
      [ { name = "machine-sp";
          ovpnFile = ../../secrets/vpn-machine-sp.age;
          port = 2222;
          authorizedKeyFiles = [ ../../data/keys/sweetango.pub ]; } ]
    '';
  };

  # Split with mkMerge rather than `//` on the attrset: deciding the shape of
  # `config` from `cfg` -- itself part of `config` -- is what infinite
  # recursion is made of. mkIf defers that decision until after the option is
  # known.
  config = lib.mkMerge [ (lib.mkIf (cfg != [ ]) {
    containers = lib.listToAttrs (lib.imap0 mkContainer cfg);

    # Lets a container reach its VPN server. It cannot reach anything else out
    # here: once the tunnel is up its default route lives inside the tunnel,
    # and the host itself is rejected by the container's own firewall.
    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
    };

    # Jump ports are offered to the tailnet and nowhere else, so a device that
    # is not on the tailnet cannot so much as knock on one.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts =
      map (tunnel: tunnel.port) cfg;

    assertions = [
      { assertion = lib.length (lib.unique (map (t: t.name) cfg))
                    == lib.length cfg;
        message = "vital.vpn.tunnels: tunnel names must be unique.";
      }
      { assertion = lib.length (lib.unique (map (t: t.port) cfg))
                    == lib.length cfg;
        message = ''
          vital.vpn.tunnels: two tunnels share a port, so only one of them
          would be reachable.
        '';
      }
      { assertion = lib.all (t: t.authorizedKeyFiles != [ ]) cfg;
        message = ''
          vital.vpn.tunnels: a tunnel with no authorized keys can never be
          used, since jumping through it is the only thing it is for.
        '';
      }
      { assertion = lib.all (t: (t.ovpnFile == null) != (t.ovpnPath == null)) cfg;
        message = ''
          vital.vpn.tunnels: set exactly one of ovpnFile (agenix-encrypted,
          in the repository) or ovpnPath (placed on the host out of band).
        '';
      }
    ];
  })

  # Only when some tunnel actually keeps its profile in the repository, so
  # that a host holding out-of-band profiles alone need not import agenix.
  (lib.mkIf (agenixTunnels != [ ]) {
    age.secrets = lib.listToAttrs (map (tunnel: {
      name = "vpn-tunnel-${tunnel.name}";
      value = {
        file = tunnel.ovpnFile;
        path = "${hostProfileDir tunnel}/${profileFile}";

        # A real file rather than a symlink into agenix's generation
        # directory, because a bind mount cannot follow the latter.
        symlink = false;
        mode = "0400";
        owner = "root";
        group = "root";
      };
    }) agenixTunnels);
  }) ];
}
