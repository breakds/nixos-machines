{ config, pkgs, lib, ... }:

let info = (import ../../../data/service-registry.nix).code-server;
    rootDir = "/var/lib/code-server";
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
      port = info.port;
      extraEnvironment = {
        SERVICE_URL = "https://open-vsx.org/vscode/gallery";
        ITEM_URL = "https://open-vsx.org/vscode/item";
      };
      extraArguments = [
        # TODO(breakds): Write a service to install the extensions.
        # Currently the user has to add installation arugment here and run it once. The server will finish
        # installation and exit. Then, remove the argument line and start the server again.
        # "--install-extension=genuitecllc.codetogether"
        "--enable-proposed-api=genuitecllc.codetogether"
      ];
    };

    services.nginx.virtualHosts = {
      "${info.domain}" = {
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
