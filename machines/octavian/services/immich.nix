{ config, lib, pkgs, ... }:

let
  registry = (import ../../../data/service-registry.nix).immich;

in {
  # Rebuild onnxruntime with CUDA so Immich's ML sidecar can use the Tesla T4.
  # Scoped to this module — does not flip nixpkgs.config.cudaSupport globally
  # (which would break packages like mxnet that mark cudaSupport as broken).
  nixpkgs.overlays = [
    (final: prev: {
      # Pull cudaPackages from unstable — same set ollama and stt-server (also
      # imported from unstable in modules/part.nix) inherit, so all three GPU
      # services share cudart/cublas/cudnn closures and auto-track the
      # unstable default through future bumps (12.9 → 13.x → ...) without
      # hardcoding a version here. The Python binding reads its CUDA deps
      # from onnxruntime.passthru.cudaPackages (nixpkgs:python-modules/
      # onnxruntime/default.nix:64), so this one override propagates.
      onnxruntime = prev.onnxruntime.override {
        cudaSupport = true;
        cudaPackages = final.unstable.cudaPackages;
      };
      immich-machine-learning = prev.immich-machine-learning.overrideAttrs (_: {
        # Upstream test_main.py asserts that force the CUDA EP into init, which
        # fails inside the Nix build sandbox. Tracked at nixpkgs#352113.
        doCheck = false;
      });
    })
  ];

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

    machine-learning = {
      enable = true;
      environment = {
        # Default 10s timeouts aren't enough for large CLIP models (e.g.
        # ViT-H-14-378) whose ONNX weights ship as many external-data
        # shards on HuggingFace — a few slow HEAD/GET round-trips cause
        # retries to exhaust and the model download to fail wholesale.
        HF_HUB_ETAG_TIMEOUT = "120";
        HF_HUB_DOWNLOAD_TIMEOUT = "120";
        # Tell ONNX Runtime's dlopen where to find the CUDA EP shared objects
        # (libonnxruntime_providers_cuda.so, etc.).
        LD_LIBRARY_PATH =
          "${pkgs.python3Packages.onnxruntime}/${pkgs.python3.sitePackages}/onnxruntime/capi";
      };
    };

    # null grants the transcoding service access to all devices — needed for
    # ffmpeg NVENC/NVDEC. This option only affects transcoding, not ML; the
    # ML sidecar's device access is controlled by its own systemd unit below.
    accelerationDevices = null;
  };

  # The Immich module sets PrivateDevices=true on the ML unit, which hides
  # /dev/nvidia*. Relax it and explicitly allow the NVIDIA character devices
  # so ONNX Runtime's CUDA EP can open the GPU.
  systemd.services.immich-machine-learning.serviceConfig = {
    PrivateDevices = lib.mkForce false;
    DeviceAllow = [
      "/dev/nvidia0"
      "/dev/nvidiactl"
      "/dev/nvidia-uvm"
      "/dev/nvidia-uvm-tools"
      "/dev/nvidia-modeset"
    ];
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
