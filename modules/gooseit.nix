{ config, pkgs, lib, ... }:

let cfg = config.programs.gooseit;

in {
  options.programs.gooseit = with lib; {
    enable = mkEnableOption "Enable the gooseit tools";

    provider = mkOption {
      type = types.str;
      default = "ollama";
      description = "This will be set to the GOOSE_PROVIDER";
    };

    model = mkOption {
      type = types.str;
      default = "qwen3:30b";
      description = "This will be set to the GOOSE_MODEL";
    };

    ollamaHost = mkOption {
      type = types.str;
      default = "http://lorian.local:11434";
      description = "This will be set to the OLLAMA_HOST";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      goose-cli
      (writeShellScriptBin "gooseit" ''
        export GOOSE_PROVIDER=${cfg.provider}
        export GOOSE_MODEL=${cfg.model}
        export OLLAMA_HOST=${cfg.ollamaHost}
        goose run -t "Please help me $1"
      '')
    ];
  };
}
