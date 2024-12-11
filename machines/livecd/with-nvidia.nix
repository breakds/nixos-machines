{config, pkgs, ...}:

{
  imports = [
    ./standard.nix
  ];
  
  config = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = true;
  };
}
