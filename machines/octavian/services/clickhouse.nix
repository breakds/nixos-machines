{ conifg, lib, pkgs, ... }:

let cfg = config.services.clickhouse-custom;

in {
  options.services.clickhouse-custom = {
    enable = mkEnableOption "Clickhouse Database Server";

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "The directory where clickhouse stores the data";
      default = "/var/lib/clickhouse";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.clickhouse = {
      name = "clickhouse";
      uid = config.ids.uids.clickhouse;
      group = "clickhouse";
      description = "ClickHouse server user";
    };

    users.groups.clickhouse.gid = config.ids.gids.clickhouse;

    systemd.services.clickhouse = {
      description = "Clickhouse server";
      wantedBy = 
    };
  };
}
