# Warehouser is a declarative empheral container.

{ container-foundation }:

{ config, pkgs, lib, ... }:

{
  config = {
    containers.warehouser = {
      ephemeral = true; # The container itself is not stateful.
      autoStart = true;
      bindMounts = {
        "/var/lib/wonder/warehouse" = {
          hostPath = "/var/lib/wonder/warehouse";
          isReadOnly = false;
        };
      };
      config = { config, pkgs, ... }: {
        imports = [
          container-foundation
        ];

        vital.container.mainUser = "breakds";
        
        networking = {
          hostName = "warehouser";
        };

        nixpkgs.config = {
          allowUnfree = true;
        };
      };
    };
  };
}
