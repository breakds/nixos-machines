{ inputs, ... }:

let self = inputs.self;

in {
  flake.nixosModules.first-party-software = {
    nixpkgs.overlays = [
      inputs.ml-pkgs.overlays.tools
      (final: prev: {
        www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
      })
      inputs.game-solutions.overlays.kiseki
      # inputs.rapit.overlays.default
    ];
  };

  flake.nixosModules.karakeep = {config, pkgs, lib, ... }: {
    imports = [
      "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/karakeep.nix"
    ];

    config = let registry = (import ../../data/service-registry.nix).karakeep; in {
      nixpkgs.overlays = [
        (final: prev: {
          karakeep = final.callPackage "${inputs.nixpkgs-unstable}/pkgs/by-name/ka/karakeep/package.nix" {};
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
        };
      };

      services.nginx.virtualHosts."${registry.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:${toString registry.ports.ui}";
      };
    };
  };

  flake.nixosConfigurations.octavian = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./.
      inputs.vital-modules.nixosModules.foundation
      inputs.nixos-home.nixosModules.breakds-home
      inputs.beancounting.nixosModules.bcounting

      self.nixosModules.graphical
      self.nixosModules.machine-learning
      self.nixosModules.first-party-software

      self.nixosModules.ollama
      inputs.personax.nixosModules.personax
      self.nixosModules.temporal
      self.nixosModules.glance
      self.nixosModules.karakeep
    ];
  };
}
