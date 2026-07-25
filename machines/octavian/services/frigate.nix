{ config, lib, ... }:

let
  go2rtcRegistry = (import ../../../data/service-registry.nix).go2rtc;
  cameraPasswordsFile = ../../../secrets/frigate-camera-passwords.age;
  cameraPasswordsConfigured = builtins.pathExists cameraPasswordsFile;

  # Add future cameras here; stream and credential wiring is generated below.
  cameras = {
    e1_zoom = {
      address = "10.77.104.39";
      username = "frigate";
      passwordEnv = "REOLINK_CATCAM_LIVING_ROOM_PASSWORD";
      streams = {
        main = "channel0_main.bcs";
        sub = "channel0_ext.bcs";
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
    settings = {
      api.listen = "127.0.0.1:${toString go2rtcRegistry.ports.api}";
      rtsp.listen = "127.0.0.1:${toString go2rtcRegistry.ports.rtsp}";

      # MSE over the Frigate nginx proxy is the initial live-view transport.
      # Keep WebRTC disabled until there is a concrete need for port 8555 or
      # two-way audio.
      webrtc.listen = "";

      streams = go2rtcStreams;
    };
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
