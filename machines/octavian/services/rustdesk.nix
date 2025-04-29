{ config, lib, pkgs, ... }:

{
  # This is strictly for use within the home network. The ID server
  # should be at `octavian.local` or its IP, and the relay servers are
  # not necessary under such scenario.
  #
  # So in the end in the client you need to fill this in the network
  # settings:
  #
  # 1. ID Server: octavian's IP
  # 2. Relay Server: <blank>
  # 3. API Server: <blank>
  # 4. Key: public key, content from /var/lib/rustdesk/id_xxx.pub
  services.rustdesk-server = {
    enable = true;
    signal = {
      enable = true;
      relayHosts = [ "127.0.0.1:21117" ];
    };
    signal.extraArgs = [
      "--mask" "10.77.1.0/24"
      "-M" "33554432"  # Larger UDP buffer
    ];
    openFirewall = true;
  };
}
