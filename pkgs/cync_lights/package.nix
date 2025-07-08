{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  voluptuous,
}:

buildHomeAssistantComponent rec {
  owner = "nikshriv";
  domain = "cync_lights";
  version = "1.0.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = "cync_lights";
    rev = "9dba8ed5cd2c2b1021cd4599f5885ee6802bb6d3";
    hash = "sha256-NCT1N6zjUYbwl0u2twEpKajvDf1ZgFx5k3IW7AtFcYQ=";
  };

  dependencies = [ voluptuous ];

  meta = with lib; {
    description = "Home Assistant Integration for controlling Cync switches, plugs, and bulbs";
    homepage = "https://github.com/nikshriv/cync_lights";
    maintainers = with maintainers; [ breakds ];
  };
}
