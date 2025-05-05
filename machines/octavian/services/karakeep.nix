{config, pkgs, nixpkgs-unstable, lib, ... }:

let registry = (import ../../../data/service-registry.nix).karakeep;

in {
  imports = [
    "${nixpkgs-unstable}/nixos/modules/services/web-apps/karakeep.nix"
  ];

  config = {
    nixpkgs.overlays = [
      (final: prev: {
        karakeep = final.callPackage "${nixpkgs-unstable}/pkgs/by-name/ka/karakeep/package.nix" {};
      })
    ];

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
