{ config, lib, pkgs, ... }:

{
  i18n = {
    # Input Method
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons  # This provides pinyin
        fcitx5-gtk
      ];
    };
  };

  # The above i18n does not start fcitx5 by default. We have to do this
  # manually. This service is adapted from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/i18n/input-method/fcitx5.nix
  systemd.user.services.fcitx5-daemon = {
    enable = true;
    script = "${config.i18n.inputMethod.package}/bin/fcitx5";
    wantedBy = [ "graphical-session.target" ];
  };  
}
