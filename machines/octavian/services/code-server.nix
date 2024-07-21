{ config, pkgs, lib, ... }:

let rootDir = "/var/lib/code-server";
    dataDir = "${rootDir}/data";
    extensionDir = "${rootDir}/extensions";

in {
  config = {
    services.code-server = {
      enable = true;
      disableUpdateCheck = true;
      user = "delegator";
      group = "delegator";
      userDataDir = "${dataDir}";
      host = "localhost";
      port = 4445;
    };

    services.nginx.virtualHosts = {
      "code.breakds.org" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${config.services.code-server.host}:${toString config.services.code-server.port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
