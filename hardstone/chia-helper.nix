{ config, pkgs, lib, ... }:

let chiaplot = pkgs.writeShellScriptBin "chiaplot" ''
      TEMP=$1
      DEST=$2
      while true; do
        date_fmt=$(date +"%Y%m%d_%H_%M_%S")
        ongoing_log_file="/home/breakds/plots/''${date_fmt}.ongoing.log"
        final_log_file="/home/breakds/plots/''${date_fmt}.log"
        echo "Start plotting on ''${TEMP} to ''${DEST}, log at ''${ongoing_log_file}"
        chiafunc plots create -t ''${TEMP} -d ''${DEST} \
            -f 8d3e6ed9dc07e3f38fb7321adc3481a95fbdea515f60ff9737c583c5644c6cf83a5e38e9f3e1fc01d43deef0fa1bd0be \
            -p ad0dce731a9ef1813dca8498fa37c3abda52ad76795a8327ea883e6aa6ee023f9e06e9a0d5ea1fa3c625261b9da18f12 \
            -n 1 > ''${ongoing_log_file} 2>&1
        mv ''${ongoing_log_file} ''${final_log_file}
        echo "Finished, log at ''${final_log_file}"
      done
    '';

in lib.mkIf config.vital.services.chia-blockchain.enable {
  environment.systemPackages = [
    chiaplot
  ];
}
