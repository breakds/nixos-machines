{ pkgs, lib, config, ... }:

{
  services.flatpak.enable = true;

  # For the sandboxed apps to work correctly, desktop integration portals need
  # to be installed. Portal backends and routing are configured by compositor
  # modules (e.g. modules/niri.nix).
  xdg.portal.enable = true;

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
