{ pkgs, lib, ... }:

let cfg = config.services.archer;

    remoteOptions = with lib; {
      options = {
        host = mkOption {
          type = types.str;
          description = "The hostname of the remote machine, where files are copied from";
        };
        port = mkOption {
          type = types.port;
          description = "The SSH port";
        };
      };
    };

in {
  options.services.archer = {
    enable = lib.mkEnableOption = "Enable the archer service.";

    remote = lib.mkOption {
      type = types.submodule 
    };
  };
}

