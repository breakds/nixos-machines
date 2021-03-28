{
  description = "Collection of my NixOS machines";

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      welderhelper = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./welderhelper ];
      };
    };
  };
}
