{config, pkgs, lib, ... }:

let
  registry = (import ../../../data/service-registry.nix).karakeep;
  meili = (import ../../../data/service-registry.nix).meilisearch;

in {
  config = {
    services.meilisearch = {
      enable = true;
      # Explicitly set the meilisearch version, because the service
      # default is an older version if the stateVersion is older than
      # 25.05. I have already manually done the migration so nothing
      # to worry about.
      package = pkgs.meilisearch;
      listenPort = meili.port;
      listenAddress = "127.0.0.1";
      dumplessUpgrade = true;
    };
    
    services.karakeep = {
      enable = true;
      meilisearch.enable = true;
      browser.enable = true;
      browser.port = registry.ports.browser;
      extraEnvironment = {
        PORT = "${toString registry.ports.ui}";
        DISABLE_SIGNUPS = "true";
        DISABLE_NEW_RELEASE_CHECK = "true";
        OLLAMA_BASE_URL = "http://localhost:${toString config.services.ollama.port}";
        INFERENCE_TEXT_MODEL = "gemma3:12b";
        INFERENCE_IMAGE_MODEL = "gemma3:12b";
        INFERENCE_CONTEXT_LENGTH = "50000";
      };
    };

    services.nginx.virtualHosts."${registry.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString registry.ports.ui}";
    };
  };
}
