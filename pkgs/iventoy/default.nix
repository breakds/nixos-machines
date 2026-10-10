{ lib, stdenvNoCC, fetchurl, buildFHSEnv, writeShellScript, bash, coreutils, gnugrep }:

let
  distribution = stdenvNoCC.mkDerivation rec {
    pname = "iventoy-distribution";
    version = "1.0.44";

    src = fetchurl {
      url = "https://github.com/ventoy/PXE/releases/download/v${version}/iventoy-${version}-linux-x86_64-free.tar.gz";
      hash = "sha256-nQUkHW2R05BexWsuHpygxGdiXZVgmx08CGW+3rxTRnk=";
    };

    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p "$out/share/iventoy"
      cp -a . "$out/share/iventoy/"
    '';
  };
in
buildFHSEnv {
  pname = "iventoy";
  inherit (distribution) version;
  targetPkgs = _: [ bash coreutils gnugrep ];

  # The upstream daemon must survive the launcher exiting.
  dieWithParent = false;
  # iVentoy mounts sysfs for machine identification and opens PXE sockets.
  extraBwrapArgs = [
    "--cap-add" "CAP_SYS_ADMIN"
    "--cap-add" "CAP_NET_ADMIN"
    "--cap-add" "CAP_NET_RAW"
    "--cap-add" "CAP_NET_BIND_SERVICE"
  ];
  runScript = writeShellScript "iventoy-launch" ''
    set -eu
    if [ "$#" -lt 2 ]; then
      echo "Usage: iventoy WORK_DIRECTORY [-R] {start|stop|status}" >&2
      exit 2
    fi
    workDir=$1
    shift
    case "''${1:-}" in
      -R) action=''${2:-} ;;
      *) action=''${1:-} ;;
    esac
    case "$action" in
      start|stop|status) ;;
      *) echo "Expected start, stop, or status." >&2; exit 2 ;;
    esac
    if [ "$(id -u)" != 0 ]; then
      echo "iVentoy requires root; run this command with sudo." >&2
      exit 1
    fi
    mkdir -p "$workDir"
    workDir=$(realpath "$workDir")
    if [ ! -e "$workDir/iventoy.sh" ]; then
      cp -R --no-preserve=ownership ${distribution}/share/iventoy/. "$workDir/"
      chmod -R u+w "$workDir"
      echo ${distribution.version} > "$workDir/.iventoy-version"
    fi
    if [ "$(cat "$workDir/.iventoy-version")" != ${distribution.version} ]; then
      echo "Work directory belongs to another iVentoy version; use a fresh directory." >&2
      exit 1
    fi
    bash "$workDir/iventoy.sh" "$@"
    # Upstream can report success even when the daemon exits during startup.
    if [ "$action" = start ]; then
      for attempt in $(seq 1 20); do
        if [ -s /var/run/iventoy.pid ] && kill -0 "$(cat /var/run/iventoy.pid)" 2>/dev/null; then
          exit 0
        fi
        sleep 0.1
      done
      echo "iVentoy failed to start; inspect $workDir/log/log.txt." >&2
      exit 1
    fi
  '';

  passthru = { inherit distribution; };
  meta = {
    description = "Network boot server for local ISO images (Free edition)";
    homepage = "https://www.iventoy.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "iventoy";
  };
}
