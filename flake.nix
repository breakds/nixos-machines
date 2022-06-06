{
  description = "Collection of my NixOS machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs2105.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?rev=e82ffe7b5f25d781eb52cc07c552899cf6f6547b";    

    # Use vital-modules, with the same nixpkgs
    vital-modules.url = "github:nixvital/vital-modules";
    vital-modules.inputs.nixpkgs.follows = "nixpkgs";

    # Use nixos-home, with the same nixpkgs
    nixos-home.url = "github:breakds/nixos-home";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";

    www-breakds-org.url = "github:breakds/www.breakds.org";
    www-breakds-org.inputs.nixpkgs.follows = "nixpkgs";

    wonder-devops.url = "git+ssh://git@github.com/quant-wonderland/devops-tools.git";
    wonder-devops.inputs.nixpkgs.follows = "nixpkgs2105";

    wonder-modules.url =
      "git+ssh://git@github.com/quant-wonderland/wonder-modules?ref=dev/22.05";
    wonder-modules.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vital-modules, nixos-home, ... }@inputs: {
    nixosConfigurations = {
      samaritan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.iphone-connect
          vital-modules.nixosModules.docker
          nixos-home.nixosModules.breakds-home
          inputs.wonder-modules.nixosModules.warehouser
          ./machines/samaritan
        ];
      };

      "horizon.GAIL3" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/horizon/GAIL3
        ];
      };

      "horizon.zero" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home-laptop
          ./machines/horizon/zero
        ];
      };

      gilgamesh = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/gilgamesh
          ({
            nixpkgs.overlays = [
              (final: prev: {
                www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
              })
            ];
          })
        ];
      };

      richelieu = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/richelieu
          ({
            nixpkgs.overlays = [
              (final: prev: {
                www-breakds-org = inputs.www-breakds-org.defaultPackage."${final.system}";
              })
            ];
          })
        ];
      };

      # The twin leaner, Lothric (Younger Prince)
      lothric = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/learners/lothric
        ];
      };

      # The twin leaner, Lorian (Elder Prince)
      lorian = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/learners/lorian
        ];
      };

      berry = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.laptop-lids
          vital-modules.nixosModules.iphone-connect
          nixos-home.nixosModules.cassandra-home
          ./machines/berry
        ];
      };

      rival = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.laptop-lids
          vital-modules.nixosModules.iphone-connect
          nixos-home.nixosModules.breakds-home-laptop
          ./machines/rival
        ];
      };

      orge = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          vital-modules.nixosModules.laptop-lids
          vital-modules.nixosModules.iphone-connect
          nixos-home.nixosModules.breakds-home-laptop
          ./machines/orge
        ];
      };

      medea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vital-modules.nixosModules.foundation
          nixos-home.nixosModules.breakds-home
          ./machines/medea
        ];
      };

      # Containers
      fortress = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./containers/fortress.nix
        ];
      };
    };

    # This is mainly for debugging and experiments purpose. Use this
    # to expose packages that you want to debug.
    packages."x86_64-linux" = let pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [
        (import ./base/overlays)
      ];
    }; in {
      inherit (pkgs) ethminer;
    };
  };
}
