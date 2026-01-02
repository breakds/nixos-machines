{ config, lib, pkgs, ... }:

let cfg = config.vital.graphical.nvidia;

in {
  options.vital.graphical.nvidia = {

    enable = lib.mkEnableOption "Add Nivdia driver.";

    withCuda = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
          When set to true, if nvidia is enabled, cuda will be installed too.
        '';
    };

    prime = {
      enable = lib.mkEnableOption ''
          Enable optimus prime mode. This is usually for laptop only.
        '';

      # TODO(breakds): Make those two "REQUIRED" when prime is enabled.
      intelBusId = lib.mkOption {
        type = lib.types.str;
        default = "PCI:0:2:0";
        description = ''
            The bus ID of the intel video card, can be found by "lspci".
          '';
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "PCI:2:0:0";
        description = ''
            The bus ID of the nvidia video card, can be found by "lspci".
          '';
      };

      offload = lib.mkEnableOption ''
        If true, put the nvidia driver in offload mode. Otherwise it will
        be in sync mode.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      nvidia.open = true;  # For using nvidia drivers >= 560
      # Kernel modesetting (KMS) is required for Wayland, PRIME sync, and
      # provides flicker-free boot, proper suspend/resume, and seamless VT switching.
      nvidia.modesetting.enable = true;
      # Nvidia PRIME The card Nvidia 940MX is non-MXM card. Needs special treatment.
      # muxless/non-MXM Optimus cards have no display outputs and show as 3D
      # Controller in lspci output, seen in most modern consumer laptops
      nvidia.prime.sync.enable = cfg.prime.enable && !cfg.prime.offload;
      nvidia.prime.offload = lib.mkIf (cfg.prime.enable && cfg.prime.offload) {
        enable = true;
        enableOffloadCmd = true;
      };

      # Bus ID of the NVIDIA GPU. You can find it using lspci
      nvidia.prime.nvidiaBusId = cfg.prime.nvidiaBusId;

      # Bus ID of the Intel GPU. You can find it using lspci
      nvidia.prime.intelBusId = cfg.prime.intelBusId;
    };
  };
}
