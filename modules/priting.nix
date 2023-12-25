{ config, pkgs, lib, ... }:

let cfg = config.vital;

in {
  config = {
    # CUPS service
    services.printing.enable = true;

    users.users."${cfg.mainUser}".extraGroups = [
      # udev sets the group of printer devices to "lp". By having this
      # group, the main user can interact with CUPS webapp.
      "lp"
    ];
  };
}
