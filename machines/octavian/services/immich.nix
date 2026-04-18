{ config, lib, pkgs, ... }:

let
  registry = (import ../../../data/service-registry.nix).immich;

in {
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = registry.port;
    mediaLocation = "/var/lib/immich";

    # Share the host PostgreSQL cluster. The module creates the immich role
    # and database, installs the vchord extension into postgresql.extraPlugins,
    # appends to shared_preload_libraries (triggering one cluster restart at
    # activation time), and runs CREATE EXTENSION inside the immich DB.
    database = {
      enable = true;
      createDB = true;
      enableVectorChord = true;
      enableVectors = false;
    };

    # Dedicated Redis for Immich (unix socket, isolated from anything else).
    redis.enable = true;

    machine-learning.enable = true;

    # null grants the service access to all hardware devices. Needed for
    # ffmpeg (NVENC/NVDEC) during video transcoding and for the ML sidecar
    # to use the Tesla T4 via CUDA.
    accelerationDevices = null;
  };

  services.nginx.virtualHosts."${registry.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString registry.port}";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 50G;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
      '';
    };
  };
}
