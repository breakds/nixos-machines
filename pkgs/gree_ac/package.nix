{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pycryptodome,
  aiofiles,
}:

buildHomeAssistantComponent rec {
  owner = "RobHofmann";
  domain = "gree";
  version = "3.6.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "HomeAssistant-GreeClimateComponent";
    rev = version;
    hash = "sha256-L46+PRg7kxByMJ5vjNHgEx2QQSFib9H0UMW1eVayCQM=";
  };

  dependencies = [ pycryptodome aiofiles ];

  meta = with lib; {
    description = "Home Assistant custom component for Gree air conditioners with direct-IP discovery";
    homepage = "https://github.com/RobHofmann/HomeAssistant-GreeClimateComponent";
    maintainers = with maintainers; [ breakds ];
  };
}
