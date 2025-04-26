{ config, lib, pkgs, ... }:

{
  services.bcounting-collectors = {
    enable = true;
    temporal = "octavian.local:7233";
    parallel = 4;
    cron.amazon = "CRON_TZ=America/Los_Angeles 0 3 * * *";
  };
}
