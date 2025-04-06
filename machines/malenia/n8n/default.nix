{ config, lib, pkgs, ... }: {
  config = {
    services.n8n = {
      enable = true;
      settings = {
        generic.timezone = "America/Los_Angeles";
      };
    };
  };
}
