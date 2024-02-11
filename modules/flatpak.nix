{ pkgs, lib, config, ... }:

{
  services.flatpak.enable = true;

  # For the sandboxed apps to work correctly, desktop integration portals need
  # to be installed. If you run GNOME, this will be handled automatically for
  # you; in other cases, you will need to add something like the following to
  # your configuration.nix.
  xdg.portal = {
    enable = true;
    # The XDG portal is used to e.g. prompt a file chooser when you need to open
    # files etc.
    config.common.default = "gtk";
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
  };

  # Add flathub on start up
  systemd.services.configure-flathub-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [pkgs.flatpak ];
    script = ''
     flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  environment.systemPackages = with pkgs; [
    appimage-run
  ];
}
