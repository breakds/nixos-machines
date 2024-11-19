{ config, lib, pkgs, ... }:

let cfg = config.services.clickhouse-wonder;

    ports = (import ../../../data/service-registry.nix).clickhouse-wonder.ports;

    config-files = pkgs.callPackage ./clickhouse-config-files.nix {
      tcpPort = ports.tcp;
      httpPort = ports.http;
      workDir = cfg.workDir;
      backupName = cfg.backup.name;
      backupPath = cfg.backup.path;
    };

in {
  ###### interface

  options.services.clickhouse-wonder = with lib; {
    enable = mkEnableOption "ClickHouse database server";

    workDir = mkOption {
      type = types.str;
      default = "/home/breakds/dataset/clickhouse";
      description = ''
         Working directory of clickhouse.
      '';
      example = "/var/lib/wonder/warehouse/clickhouse";
    };

    backup = mkOption {
      type = types.submodule {
        options = {
          name = mkOption { type = types.str; };
          path = mkOption { type = types.str; };
        };
      };
      description = ''
        Configures the clickhouse backup file directory and name.

        Note that in order to be able to restore from backup files, those two
        must be configured EXACTLY THE SAME as the clickhouse instance who
        creates those backup files.
      '';
      default = {
        name = "backups1";
        path = "/var/lib/wonder/warehouse/clickhouse/ClickHouseBackup";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "breakds";
      description = lib.mdDoc "User account under which clickhouse-server runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = lib.mdDoc "Group under which clickhous-server runs.";
    };
  };

  ###### implementation

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.workDir} 775 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.clickhouse = {
      description = "ClickHouse server for wonderland";

      wantedBy = [ "multi-user.target" ];

      after = [ "network.target" ];

      serviceConfig = {
        # As a database service, clickhouse may take some time to initialize
        # itself before it is considered ready. It is designed to explicitly
        # send "sd_notify" message to systemd.
        Type = "notify";
        User = cfg.user;
        Group = cfg.group;
        # Allows the process to adjust its priority (nice value) and scheduling
        # policies. This is useful for database services such as clickhouse to
        # optimize their scheduling for better performance under heavy loads.
        AmbientCapabilities = "CAP_SYS_NICE";
        ExecStart = "${pkgs.clickhouse}/bin/clickhouse-server --config-file=${config-files}/config.xml";
        # Ask systemd to wait indefinitely for the service to signal readiness.
        TimeoutStartSec = "infinity";
      };

      environment = {
        # Switching off watchdog is very important for sd_notify to work correctly.
        CLICKHOUSE_WATCHDOG_ENABLE = "0";
      };
    };

    environment.systemPackages = [ pkgs.clickhouse ];

    # startup requires a `/etc/localtime` which only if exists if `time.timeZone != null`
    time.timeZone = lib.mkDefault "America/Los_Angeles";
  };
}
