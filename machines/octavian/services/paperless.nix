{ config, lib, pkgs, ... }:

let info = (import ../../../data/service-registry.nix).paperless;

in {
  services.paperless = {
    enable = true;
    port = info.port;
    dataDir = "/var/lib/paperless/data";
    mediaDir = "/var/lib/filerun/user-files/paperless/media";
    consumptionDir = "/var/lib/filerun/user-files/paperless/incoming";
    consumptionDirIsPublic = true;  # Basically "chmod o+w"
    extraConfig = {
      PAPERLESS_ADMIN_USER = "breakds";
    };
  };

  services.nginx.virtualHosts = {
    "${info.domain}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString info.port}";
      };
    };
  };

  # Above I have set the comsumption directory and media directory under the
  # filerun directory. I have added g+w to that directory so that paperless can
  # read/write those directories as long as it belongs to the "delegator" group.
  users.users."paperless" = lib.mkIf config.services.paperless.enable {
    extraGroups = [ "delegator" ];
  };
}
