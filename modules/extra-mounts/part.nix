{ inputs, ... }:

{
  flake.nixosModules = {
    wonder-datahub = { config, lib, pkgs, ... }: {
      config = let nfsOptions = [ "rw" "vers=3" "proto=tcp" ]; in {
        fileSystems."/var/lib/wonder/warehouseDatahubNFS" = {
          device = "datahub:/export/share";
          fsType = "nfs";
          options = nfsOptions;
        };

        fileSystems."/var/lib/wonder/warehouseBishopNFS" = {
          device = "bishop:/export/share";
          fsType = "nfs";
          options = nfsOptions;
        };
      };
    };
  };
}
