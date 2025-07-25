{ config, lib, pkgs, ... }:

{
  services.psynker = {
    enable = true;
    port = 9119;
    domain = "psynkrec.breakds.org";
  };
}
