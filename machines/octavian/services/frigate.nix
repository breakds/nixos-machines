{ config, lib, pkgs, ... }:

let
  serviceRegistry = import ../../../data/service-registry.nix;
  go2rtcRegistry = serviceRegistry.go2rtc;
  frigateRegistry = serviceRegistry.frigate;
  cameraPasswordsFile = ../../../secrets/frigate-camera-passwords.age;
  cameraPasswordsConfigured = builtins.pathExists cameraPasswordsFile;

  # Frigate's documented YOLOX example uses this upstream 416x416 model.
  # ONNX Runtime keeps it loaded on the T4 and uses CUDA graphs automatically.
  yoloxTinyModel = pkgs.fetchurl {
    url =
      "https://github.com/Megvii-BaseDetection/YOLOX/releases/download/0.1.1rc0/yolox_tiny.onnx";
    hash = "sha256-QnzDZtNOJ/96A+KJm142cUJcJi6iKR+Iu5QrwcxwsPc=";
  };
  coco80LabelMap =
    "${pkgs.frigate.src}/docker/main/rootfs/labelmap/coco-80.txt";

  # Add future cameras here; stream and credential wiring is generated below.
  cameras = {
    catcam_living_room = {
      address = "10.77.104.39";
      username = "frigate";
      passwordEnv = "FRIGATE_REOLINK_CATCAM_LIVING_ROOM_PASSWORD";
      onvifPort = 8000;

      # Change only this value to compare the camera's HTTP-FLV and RTSP
      # implementations. Each profile records the matching endpoints and the
      # actual resolution of its detection stream.
      streamTransport = "rtsp";
      streamProfiles = {
        http-flv = {
          main = "channel0_main.bcs";
          sub = "channel0_ext.bcs";
          detectResolution = {
            width = 896;
            height = 512;
          };
        };
        rtsp = {
          main = "Preview_01_main";
          sub = "Preview_01_sub";
          detectResolution = {
            width = 640;
            height = 360;
          };
        };
      };
      detectFps = 5;

      # Mask only the camera-rendered timestamp. Its changing seconds were
      # continuously creating motion regions across the top of the image.
      motionMasks = [ "0.27,0.00,0.70,0.00,0.70,0.08,0.27,0.08" ];
      recordingRetentionDays = 14;
    };
  };

  mkGo2rtcEnvironmentToken = name: "$" + "{${name}}";
  mkFrigateEnvironmentToken = name: "{${name}}";

  mkReolinkHttpFlvUrl = camera: stream:
    "http://${camera.address}/flv?port=1935&app=bcs&stream=${stream}"
    + "&user=${camera.username}"
    + "&password=${mkGo2rtcEnvironmentToken camera.passwordEnv}";

  mkReolinkRtspUrl = camera: stream:
    "rtsp://${camera.username}:"
    + "${mkGo2rtcEnvironmentToken camera.passwordEnv}"
    + "@${camera.address}:554/${stream}";

  getStreamProfile = name: camera:
    camera.streamProfiles.${camera.streamTransport} or (throw
      "Camera ${name} has no ${camera.streamTransport} stream profile");

  mkGo2rtcSource = camera: streamName: stream:
    if camera.streamTransport == "http-flv" then
      "ffmpeg:${mkReolinkHttpFlvUrl camera stream}" + "#video=copy"
      + lib.optionalString (streamName == "main") "#audio=copy"
    else if camera.streamTransport == "rtsp" then
    # This Reolink's native RTSP stream starts with discontinuous timestamps.
    # Remux it through FFmpeg so go2rtc's consumers receive a monotonic stream;
    # copy mode does not decode or re-encode either track.
      "ffmpeg:${mkReolinkRtspUrl camera stream}" + "#video=copy"
      + lib.optionalString (streamName == "main") "#audio=copy"
    else
      throw "Unsupported Reolink stream transport: ${camera.streamTransport}";

  go2rtcStreams = lib.concatMapAttrs (name: camera:
    let profile = getStreamProfile name camera;
    in {
      "${name}_main" = mkGo2rtcSource camera "main" profile.main;
      "${name}_sub" = mkGo2rtcSource camera "sub" profile.sub;
    }) cameras;

  go2rtcSettings = {
    api.listen = "127.0.0.1:${toString go2rtcRegistry.ports.api}";
    rtsp.listen = "127.0.0.1:${toString go2rtcRegistry.ports.rtsp}";

    # MSE over the Frigate nginx proxy is the initial live-view transport.
    # Keep WebRTC disabled until there is a concrete need for port 8555 or
    # two-way audio.
    webrtc.listen = "";

    streams = go2rtcStreams;
  };

  mkGo2rtcRtspUrl = stream:
    "rtsp://127.0.0.1:${toString go2rtcRegistry.ports.rtsp}/${stream}";

  # Frigate's native NixOS service talks to the separately managed go2rtc
  # process, but its UI still needs a matching stream inventory to enable MSE,
  # audio capability discovery, and manual stream selection. Point this
  # password-free inventory back to go2rtc's loopback RTSP restreams; only the
  # go2rtc service needs the camera credentials.
  frigateGo2rtcStreams =
    lib.mapAttrs (name: _: mkGo2rtcRtspUrl name) go2rtcStreams;

  mkFrigateCamera = name: camera:
    let profile = getStreamProfile name camera;
    in {
      ffmpeg.inputs = [
        {
          path = mkGo2rtcRtspUrl "${name}_sub";
          input_args = "preset-rtsp-restream";
          roles = [ "detect" ];
        }
        {
          path = mkGo2rtcRtspUrl "${name}_main";
          input_args = "preset-rtsp-restream";
          roles = [ "record" ];
        }
      ];

      # Sample the camera's 10 FPS substream at 5 FPS to reduce decode and
      # inference work. Resolution follows the selected transport profile.
      detect = profile.detectResolution // {
        enabled = true;
        fps = camera.detectFps;
      };

      objects.track = [ "cat" ];

      motion.mask = camera.motionMasks;

      # Keep the review policy closed to cats. "Detection" is Frigate's
      # lower-priority review category and does not imply an external alert.
      review = {
        alerts.labels = [ ];
        detections.labels = [ "cat" ];
      };

      # Main is continuously remuxed into Frigate's rolling cache, but only
      # complete cat review intervals are retained on ZFS. No continuous or
      # generic motion timeline is kept.
      record = {
        enabled = true;
        continuous.days = 0;
        motion.days = 0;
        alerts.retain.days = 0;
        detections = {
          pre_capture = 5;
          post_capture = 5;
          retain = {
            days = camera.recordingRetentionDays;
            mode = "all";
          };
        };
      };

      live.streams = {
        "Main Stream" = "${name}_main";
        "Sub Stream" = "${name}_sub";
      };

      onvif = {
        host = camera.address;
        port = camera.onvifPort;
        user = camera.username;
        password = mkFrigateEnvironmentToken camera.passwordEnv;

        # Manual PTZ is in scope; Reolink autotracking is not.
        autotracking.enabled = false;
      };
    };

  frigateCameras = lib.mapAttrs mkFrigateCamera cameras;

  # Build-time config validation has no access to runtime agenix secrets.
  # Supply non-secret placeholders so Frigate can validate the ONVIF schema.
  frigateConfigCheckEnvironment = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (_: camera: "export ${camera.passwordEnv}=config-check-placeholder")
    cameras);
in {
  # The encrypted secret is intentionally absent from the initial deployment.
  # After the shared camera-password file is created and committed, this
  # declaration causes agenix to decrypt it only at runtime.
  age.secrets = lib.optionalAttrs cameraPasswordsConfigured {
    frigate-camera-passwords = {
      file = cameraPasswordsFile;
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };

  services.go2rtc = {
    enable = true;
    settings = go2rtcSettings;
  };

  services.frigate = {
    enable = true;
    hostname = frigateRegistry.domain;
    preCheckConfig = frigateConfigCheckEnvironment;
    settings = {
      auth = {
        enabled = true;
        cookie_secure = true;
        failed_login_rate_limit = "1/second;5/minute;20/hour";
      };
      mqtt.enabled = false;
      birdseye.enabled = false;
      detectors.t4 = {
        type = "onnx";
        device = "0";
      };
      model = {
        path = toString yoloxTinyModel;
        model_type = "yolox";
        width = 416;
        height = 416;
        input_tensor = "nchw";
        input_pixel_format = "bgr";
        input_dtype = "float_denorm";
        labelmap_path = coco80LabelMap;
      };
      go2rtc.streams = frigateGo2rtcStreams;
      cameras = frigateCameras;
    };
  };

  # nginx is the only public entry point. The Frigate module keeps its API,
  # websocket, video-output, and go2rtc upstreams on loopback.
  services.nginx.virtualHosts.${frigateRegistry.domain} = {
    enableACME = true;
    forceSSL = true;

    # The UI root is enough to establish HSTS for subsequent browser requests.
    locations."/".extraConfig = lib.mkAfter ''
      add_header Strict-Transport-Security "max-age=31536000" always;
    '';
  };

  # go2rtc uses the credential for camera streaming and Frigate uses it for
  # ONVIF. Both resolve it only from the runtime agenix environment file.
  systemd.services = lib.mkIf cameraPasswordsConfigured {
    go2rtc = {
      restartTriggers = [ cameraPasswordsFile ];
      serviceConfig.EnvironmentFile =
        config.age.secrets.frigate-camera-passwords.path;
    };
    frigate = {
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
      restartTriggers = [ cameraPasswordsFile ];
      unitConfig.ConditionPathIsMountPoint = [
        "/var/lib/frigate"
        "/var/lib/frigate/recordings"
        "/var/lib/frigate/exports"
      ];
      serviceConfig.EnvironmentFile =
        config.age.secrets.frigate-camera-passwords.path;
    };
  };
}
