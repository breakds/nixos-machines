{ config, lib, pkgs, ... }:

let cfg = config.services.post-box;

in {
  options.services.post-box = {
    enable = lib.mkEnableOption "Enable the postgresql box container";

    # PostgreSQL data is stored inside the container's state directory:
    # /var/lib/nixos-containers/post-box/var/lib/postgresql/18/

    hostIp = lib.mkOption {
      type = lib.types.str;
      default = "10.55.1.1";
      description = "Host IP on the virtual network.";
    };

    localIp = lib.mkOption {
      type = lib.types.str;
      default = "10.55.1.2";
      description = "Container IP address (e.g. 10.55.1.2).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "The user to create inside the container.";
    };

    keyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "SSH authorized key files for the user.";
    };
  };
  
  config = lib.mkIf cfg.enable {
    containers.post-box = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = cfg.hostIp;
      localAddress = cfg.localIp;

      config = { ... }: {
        nixpkgs.pkgs = pkgs;
        system.stateVersion = config.system.stateVersion;

        networking.firewall.allowedTCPPorts = [ 5432 ];

        users.users.${cfg.user} = {
          isNormalUser = true;
          home = "/home/${cfg.user}";
          uid = 1000;
          openssh.authorizedKeys.keyFiles = cfg.keyFiles;
        };

        environment.systemPackages = with pkgs; [
          postgresql_18
        ];

        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
        };

        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_18;
          dataDir = "/var/lib/postgresql/${pkgs.postgresql_18.psqlSchema}";
          
          ensureUsers = [
            {
              name = cfg.user;
            }
          ];

          settings = {
            listen_addresses = lib.mkForce "*";
            shared_buffers = "128MB";
            effective_cache_size = "1GB";
            work_mem = "8MB";
            maintenance_work_mem = "32MB";
            random_page_cost = 1.1;
            effective_io_concurrency = 200;
            wal_buffers = "8MB";
            max_wal_size = "1GB";
            log_min_duration_statement = 250;
          };

          authentication = lib.mkOverride 10 ''
            # TYPE  DATABASE  USER  ADDRESS       METHOD
            local   all       all                 peer
            host    all       all   127.0.0.1/32  trust
            host    all       all   ::1/128       trust
            host    all       all   ${cfg.hostIp}/32  trust
          '';
        };
      };
    };
  };
}
