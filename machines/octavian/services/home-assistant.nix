{ config, pkgs, lib, ... }:

let
  registry = (import ../../../data/service-registry.nix).home-assistant;
  haPkgs = config.services.home-assistant.package.python.pkgs;

in {
  # NOTE: When starting a fresh instance, you will need to click "CREATE MY
  # SMART HOME" and set up your username and password.
  services.home-assistant = {
    enable = true;
    openFirewall = false;

    config = {
      default_config = {};

      http = {
        server_host = "127.0.0.1";
        server_port = registry.port;
        use_x_forwarded_for = true;
        trusted_proxies = [
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

      tts = [
        {
          platform = "picotts";
          language = "en-US";
        }
      ];
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
      "picotts"
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
}
