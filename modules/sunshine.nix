{ config, pkgs, lib, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;  # Port 47974 - 47990, TCP + UDP

    settings = {
      output_name = 2;
    };
  };

  systemd.user.services.sunshine = let
    swaymsg = "${pkgs.sway}/bin/swaymsg";

    jq = "${pkgs.jq}/bin/jq";

    ensureHeadless = pkgs.writeShellScriptBin "sway-ensure-headless" ''
      set -euo pipefail

      HEADLESS_OUTPUTS=$(
        ${swaymsg} -t get_outputs -r | ${jq} -r '.[] | select(.name | startswith("HEADLESS-")) | .name'
      )

      if [ -z "$HEADLESS_OUTPUTS" ]; then
        ${swaymsg} create_output

        HEADLESS_OUTPUTS=$(
          ${swaymsg} -t get_outputs -r | ${jq} -r '.[] | select(.name | startswith("HEADLESS-")) | .name'
        )
      fi

      for out in $HEADLESS_OUTPUTS; do
        ${swaymsg} output "$out" mode 5120x1440@60Hz
      done
    '';

    cleanupHeadless = pkgs.writeShellScriptBin "sway-cleanup-headless" ''
      set -euo pipefail

      HEADLESS_OUTPUTS=$(
        ${swaymsg} -t get_outputs -r | ${jq} -r '.[] | select(.name | startswith("HEADLESS-")) | .name'
      )

      for out in $HEADLESS_OUTPUTS; do
        ${swaymsg} output "$out" unplug
      done
    '';
  in {
    serviceConfig = {
      ExecStartPre = [ "${ensureHeadless}/bin/sway-ensure-headless" ];
      ExecStopPost = [ "${cleanupHeadless}/bin/sway-cleanup-headless" ];
    };
  };
}
