{ config, pkgs, ... }:

let
  basalt = pkgs.unstable.callPackage ../../../pkgs/basalt { };
  model = "/var/lib/basalt/models/DeepSeek-V4.1-Flash-1017-UD-IQ2_XXS.basalt";
  settings = pkgs.writeText "basalt-config.json" (builtins.toJSON {
    version = 2;
    models = [{
      inherit model;
      gpu = "0,1";
      max-context = 524288;
      kv = "fp8";
      parallel = 1;
      slot-full-context = true;
      vision = "off";
    }];
    engine.spec = 8;
    engine.ram-reserve-mib = 16384;
    server = {
      host = "0.0.0.0";
      port = 11081;
    };
  });
in {
  environment.systemPackages = [ basalt ];
  networking.firewall.allowedTCPPorts = [ 11081 ];

  systemd.services.basalt-main = {
    description = "Basalt DeepSeek inference server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "lorian-nvidia-power-limit.service" ];
    conflicts = [ "vllm-main.service" ];
    path = [ config.hardware.nvidia.package.bin ];
    environment = {
      HOME = "%S/basalt";
      XDG_CACHE_HOME = "%S/basalt/cache";
      CUDA_CACHE_PATH = "%S/basalt/cache/cuda";
    };
    serviceConfig = {
      Type = "exec";
      DynamicUser = true;
      StateDirectory = [ "basalt" "basalt/models" "basalt/cache/cuda" ];
      StateDirectoryMode = "0750";
      WorkingDirectory = "%S/basalt";
      # ExecCondition runs after directory setup; an absent pack skips startup.
      ExecCondition = "${pkgs.coreutils}/bin/test -r ${model}";
      ExecStart = "${basalt}/bin/basalt serve --config ${settings}";
      Restart = "on-failure";
      RestartSec = 10;
      TimeoutStopSec = 120;
      LimitMEMLOCK = "infinity";
      SupplementaryGroups = [ "render" "video" ];
    };
  };
}
