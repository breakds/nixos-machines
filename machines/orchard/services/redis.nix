{ config, pkgs, lib, ... }:{

{
  config = {
    services.redis.servers = {
      voyage = {
        enable = true;
        user = "cassandra";
        group = "users";
        port = 6379;
      };
    };
  };
}
