{ config, lib, ... }:

let
  serviceRegistry = import ../../../data/service-registry.nix;
  go2rtcRegistry = serviceRegistry.go2rtc;
  frigateRegistry = serviceRegistry.frigate;
  cameraPasswordsFile = ../../../secrets/frigate-camera-passwords.age;
  cameraPasswordsConfigured = builtins.pathExists cameraPasswordsFile;

  # Add future cameras here; stream and credential wiring is generated below.
  cameras = {
    catcam_living_room = {
      address = "10.77.104.39";
      username = "frigate";
      passwordEnv = "REOLINK_CATCAM_LIVING_ROOM_PASSWORD";
      streams = {
        main = "channel0_main.bcs";
        sub = "channel0_ext.bcs";
      };
      detect = {
        width = 896;
        height = 512;
        fps = 10;
      };
    };
  };

  mkEnvironmentToken = name: "$" + "{${name}}";

  mkReolinkHttpFlvUrl = camera: stream:
    "http://${camera.address}/flv?port=1935&app=bcs&stream=${stream}"
    + "&user=${camera.username}"
    + "&password=${mkEnvironmentToken camera.passwordEnv}";

  go2rtcStreams = lib.concatMapAttrs (name: camera: {
    "${name}_main" = "ffmpeg:${mkReolinkHttpFlvUrl camera camera.streams.main}"
      + "#video=copy#audio=copy";
    "${name}_sub" = "ffmpeg:${mkReolinkHttpFlvUrl camera camera.streams.sub}"
      + "#video=copy";
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

  # Frigate's native NixOS service talks to the separately managed go2rtc
  # process, but its UI still needs a matching stream inventory to enable MSE,
  # audio capability discovery, and manual stream selection. Point this
  # password-free inventory back to go2rtc's loopback RTSP restreams; only the
  # go2rtc service needs the camera credentials.
  frigateGo2rtcStreams = lib.mapAttrs (name: _:
    "rtsp://127.0.0.1:${toString go2rtcRegistry.ports.rtsp}/${name}"
  ) go2rtcStreams;

  mkFrigateCamera = name: camera: {
    ffmpeg.inputs = [{
      path =
        "rtsp://127.0.0.1:${toString go2rtcRegistry.ports.rtsp}/${name}_sub";
      input_args = "preset-rtsp-restream";
      roles = [ "detect" ];
    }];

    # Frigate still decodes the detect input for motion, snapshots, and its
    # low-bandwidth live-view fallback. Object inference remains disabled.
    detect = camera.detect // { enabled = false; };

    record.enabled = false;

    live.streams = {
      "Main Stream" = "${name}_main";
      "Sub Stream" = "${name}_sub";
    };
  };

  frigateCameras = lib.mapAttrs mkFrigateCamera cameras;
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
    settings = {
      auth = {
        enabled = true;
        cookie_secure = true;
        failed_login_rate_limit = "1/second;5/minute;20/hour";
      };
      mqtt.enabled = false;
      birdseye.enabled = false;
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

  # go2rtc natively resolves each password token from its environment. Until
  # the age file exists, literal placeholders remain in the loopback-only
  # configuration and no password is provisioned.
  systemd.services.go2rtc = lib.mkIf cameraPasswordsConfigured {
    restartTriggers = [ cameraPasswordsFile ];
    serviceConfig.EnvironmentFile =
      config.age.secrets.frigate-camera-passwords.path;
  };
}
