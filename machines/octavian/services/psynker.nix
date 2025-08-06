{ config, lib, pkgs, ... }:

{
  services.psynker = {
    enable = true;
    port = 9119;
  };
}
