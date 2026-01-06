{ config, pkgs, lib, ... }:

let
  registry = (import ../../../data/service-registry.nix).home-assistant;
  haPkgs = config.services.home-assistant.package.python.pkgs;

in {
  # NOTE: When starting a fresh instance, you will need to click "CREATE MY
  # SMART HOME" and set up your username and password.
  services.home-assistant = {
    enable = true;
    openFirewall = true;

    config = {
      default_config = {};

      http = {
        server_host = "0.0.0.0";
        server_port = registry.port;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "0.0.0.0"
          "127.0.0.1"
          "::1"
        ];
      };

      # Basic configuration
      homeassistant = {
        name = "BYCQ";
        longitude = -122.11206;
        latitude = 37.38086;
        unit_system = "metric";
        temperature_unit = "C";
        time_zone = "America/Los_Angeles";
        # external_url ensures HA issues links and cookies matching your public
        # domain so the Companion app’s login flow callbacks hit the right address.
        external_url = "https://${registry.domain}";
      };

      "automation ui" = "!include automations.yaml";

      ffmpeg = {};
    };

    extraComponents = [
      "mqtt"
      "esphome"
      "xiaomi"
      "xiaomi_aqara"
      "nest"
      "tuya"
      "yi"
      "bthome"
      "ecovacs"
      "whisper"
      "elevenlabs"
      "wyoming"
      "piper"
      "ollama"
      "go2rtc"
      "matter"
    ];

    customComponents = with pkgs.home-assistant-custom-components; [
      localtuya
      xiaomi_gateway3
    ] ++ [
      (haPkgs.callPackage ../../../pkgs/cync_lights/package.nix {})
    ];

    extraPackages = python-pkgs: with python-pkgs; [
      psycopg2       # PostgreSQL support
      gtts           # Google's TTS
      aiousbwatcher  # USB
      radios
      pymetno
      pychromecast
      xiaomi-ble
      pyxiaomigateway
      python-miio
      miauth
      androidtvremote2
      spotifyaio
      rachiopy
      yeelight
      ibeacon-ble
      pyipp
      grpcio          # For Nest
      grpcio-tools    # For Nest
      grpcio-status   # For Nest
      pyatv
      zigpy
      tinytuya
      wyoming
      elevenlabs
      ollama
      aiohomekit
      ha-ffmpeg
      python-otbr-api

      # Weather
      accuweather
      pyopenweathermap

      # Calendar
      gcal-sync
      oauth2client
    ];
  };

  services.nginx.virtualHosts."${registry.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString registry.port}";
      proxyWebsockets = true;
    };
  };

  services.wyoming = let wyoming-registry = (import ../../../data/service-registry.nix).wyoming;
  in {
    piper.servers.default = {
      enable = true;
      voice = "en-us-ryan-high";
      uri = "tcp://0.0.0.0:${toString wyoming-registry.piper.port}";
    };

    # Faster whisper is disabled, as we will use stt-server.
    faster-whisper.servers.default = {
      enable = false;
      model = "medium.en";
      device = "cuda";
      language = "en";
      beamSize = 5;
      uri = "tcp://0.0.0.0:${toString wyoming-registry.faster-whisper.port}";
      initialPrompt = ''
        The user is talking to its AI assistant in his or her home.
      '';
    };

    openwakeword = {
      enable = true;
      uri = "tcp://0.0.0.0:${toString wyoming-registry.openwakeword.port}";
      threshold = 0.9;
    };
  };

  services.matter-server = let reg = (import ../../../data/service-registry.nix).matter-server;
  in {
    enable = true;
    port = reg.port;
  };
}
