{ config, pkgs, lib, ... }:

{
  config = {

    # nixpkgs.overlays = [
    #   (final: prev: {
    #     steam = prev.steam.override {
    #       # TODO(breakds): Figure out what are the actual necessary libraries.
    #       extraPkgs = p: with pkgs;
    #         let xorgdeps = with xorg; [
    #               libX11 libXrender libXrandr libxcb libXmu libpthreadstubs libXext libXdmcp
    #               libXxf86vm libXinerama libSM libXv libXaw libXi libXcursor libXcomposite
	  #             ];
	  #         in [
    #           glib-networking
    #           libxkbcommon
	  #           fluidsynth hidapi mesa libdrm
    #           perl which p7zip gnused gnugrep psmisc opencl-headers
	  #           cups lcms2 mpg123 cairo unixODBC samba4 sane-backends openldap ocl-icd utillinux
	  #           fribidi
    #           libsndfile libtheora libogg libvorbis libopus libGLU libpcap libpulseaudio
    #           libao libusb libevdev udev libgcrypt libxml2 libusb libpng libmpeg2 libv4l
    #           libjpeg libxkbcommon libass libcdio libjack2 libsamplerate libzip libmad libaio
    #           libcap libtiff libva libgphoto2 libxslt libsndfile giflib zlib glib
    #           alsaLib zziplib bash dbus keyutils zip cabextract freetype unzip coreutils
    #           readline gcc SDL SDL2 curl graphite2 gtk2 gtk3 udev ncurses wayland libglvnd
    #           vulkan-loader xdg_utils sqlite gnutls libbsd
    #           openldap
    #           xorg.xrandr
    #           xorg.xinput
    #           zlib
    #           dbus
    #           freetype
    #           glib
    #           atk
    #           cairo
    #           gdk-pixbuf
    #           pango
    #           fontconfig
    #           xorg.libxcb
	  #           libkrb5
	  #           nss
	  #           qt5
    #         ] ++ xorgdeps;
    #     };
    #   })
    # ];
    
    # # https://github.com/NixOS/nixpkgs/issues/45492#issuecomment-418903252
    # # Set limits for esync.
    # systemd.extraConfig = "DefaultLimitNOFILE=1048576";

    # security.pam.loginLimits = [{
    #   domain = "*";
    #   type = "hard";
    #   item = "nofile";
    #   value = "1048576";
    # }];
    
    # environment.systemPackages = with pkgs; [
    #   wine
    #   steam
    #   steam.run
    #   obs-studio
    #   imagemagick
    #   steam-run-native
    # ];
    
    programs.steam = {
      enable = true;
      # remotePlay.openFirewall = true;
      # dedicatedServer.openFirewall = true;
    };
  };
}
