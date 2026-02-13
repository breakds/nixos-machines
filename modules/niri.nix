{ pkgs, ... }:

{
  programs.niri.enable = true;

  programs.ydotool.enable = true;

  environment.systemPackages = with pkgs; [ ydotool pass-fuzzel slurp wl-screenrec];

  # Niri implements GNOME Mutter ScreenCast/RemoteDesktop D-Bus interfaces (not
  # wlroots protocols), so it needs the gnome portal backend for screen sharing
  # to work (Google Meet, OBS PipeWire capture, etc.).
  #
  # xdg-desktop-portal only looks for *-portals.conf in config dirs (/etc/xdg/),
  # not the data dir where niri installs its niri-portals.conf, so we set the
  # portal routing explicitly.
  xdg.portal = {
    enable = true;
    config.niri = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };
}
