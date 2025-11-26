{ config, lib, ... }:

{
  config = {
    services.komga = {
      enable = true;
      openFirewall = true;
      settings = {
        server = {
          port = 25600;
        };
      };
    };
  };
}
