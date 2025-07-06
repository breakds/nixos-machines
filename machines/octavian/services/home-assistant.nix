{ config, pkgs, lib, ... }:

let registry = (import ../../../data/service-registry.nix).home-assistant;

in {
  services.home-assistant = {
    enable = true;
    openFirewall = true;

    config = {
      http = {
        server_host = "0.0.0.0";
        server_port = registry.port;
      };

      # Basic configuration
      homeassistant = {
        name = "BYCQ";
        longitude = -122.11206;
        latitude = 37.38086;
        unit_system = "metric";
        temperature_unit = "C";
        time_zone = "America/Los_Angeles";
      };
    };

    extraComponents = [
      "xiaomi"
      "nest"
      "tuya"
    ];

    extraPackages = python-pkgs: with python-pkgs; [
      psycopg2       # PostgreSQL support
    ];
  };

  # services.nginx.virtualHosts."${registry.domain}" = {
  #   enableACME = true;
  #   forceSSL = true;
  #   locations."/".proxyPass = "http://localhost:${toString registry.port}";
  # };
}
