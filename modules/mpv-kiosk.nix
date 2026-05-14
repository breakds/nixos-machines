{ config, lib, pkgs, ... }:

let
  cfg = config.services.mpvKiosk;

  homeDir = if cfg.home == null then "/home/${cfg.user}" else cfg.home;
  mediaDir = if cfg.mediaDir == null then "${homeDir}/Videos" else cfg.mediaDir;
  mediaDirGroup =
    if cfg.mediaDirGroup == null then cfg.user else cfg.mediaDirGroup;

  videoFindExpr = lib.concatMapStringsSep " -o "
    (extension: "-iname ${lib.escapeShellArg ("*." + extension)}")
    cfg.videoExtensions;

  defaultMpvArgs = [
    "--fullscreen"
    "--loop-playlist=inf"
    "--no-osc"
    "--no-input-default-bindings"
    "--cursor-autohide=always"
    "--hwdec=auto-safe"
  ];

  mpvArgs =
    lib.concatMapStringsSep " \\\n          " (arg: lib.escapeShellArg arg)
    (defaultMpvArgs ++ cfg.extraMpvArgs ++ [ mediaDir ]);

  kioskRunner = pkgs.writeShellScript "mpv-kiosk-runner" ''
    set -u

    while true; do
      if ${pkgs.findutils}/bin/find ${
        lib.escapeShellArg mediaDir
      } -maxdepth 1 -type f \
          \( ${videoFindExpr} \) \
          | ${pkgs.gnugrep}/bin/grep -q .; then
        echo "mpv-kiosk: starting mpv"
        ${cfg.mpvPackage}/bin/mpv \
          ${mpvArgs}
        echo "mpv-kiosk: mpv exited; restarting in ${toString cfg.retrySec}s"
      else
        echo "mpv-kiosk: waiting for videos in ${mediaDir}"
      fi

      sleep ${toString cfg.retrySec}
    done
  '';

in {
  options.services.mpvKiosk = {
    enable = lib.mkEnableOption "a Cage + mpv video kiosk";

    user = lib.mkOption {
      type = lib.types.str;
      default = "kiosk";
      description = "User that owns and runs the kiosk session.";
    };

    home = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Home directory for the kiosk user. Defaults to /home/<user>.
      '';
    };

    mediaDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Directory containing videos to loop. Defaults to <home>/Videos.
      '';
    };

    createMediaDir = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to create the media directory at boot.";
    };

    mediaDirMode = lib.mkOption {
      type = lib.types.str;
      default = "0755";
      description = "Mode for the media directory tmpfiles rule.";
    };

    mediaDirGroup = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Group owner for the media directory. Defaults to the kiosk user.
      '';
    };

    videoExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "mp4" "mkv" "mov" "webm" "m4v" ];
      description = "Video file extensions the kiosk runner should wait for.";
    };

    mpvPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.mpv;
      defaultText = lib.literalExpression "pkgs.mpv";
      description = "mpv package used by the kiosk runner.";
    };

    extraMpvArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments passed to mpv.";
    };

    retrySec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description =
        "Seconds to wait before retrying after no media or mpv exit.";
    };

    restartSec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description =
        "Seconds systemd waits before restarting Cage after failure.";
    };

    disableConsoleBlanking = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to add consoleblank=0 to kernel parameters.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.videoExtensions != [ ];
      message = "services.mpvKiosk.videoExtensions must not be empty.";
    }];

    users.users.${cfg.user} = {
      isNormalUser = true;
      home = homeDir;
      createHome = true;
      extraGroups = [ "video" "audio" "render" "input" ];
    };

    boot.kernelParams =
      lib.mkIf cfg.disableConsoleBlanking [ "consoleblank=0" ];

    systemd.tmpfiles.rules = lib.optional cfg.createMediaDir
      "d ${mediaDir} ${cfg.mediaDirMode} ${cfg.user} ${mediaDirGroup} -";

    services.cage = {
      enable = true;
      user = cfg.user;
      program = "${kioskRunner}";
    };

    systemd.services."cage-tty1".serviceConfig = {
      Restart = "always";
      RestartSec = cfg.restartSec;
      StartLimitIntervalSec = 0;
    };

    environment.systemPackages = [ cfg.mpvPackage ];
  };
}
