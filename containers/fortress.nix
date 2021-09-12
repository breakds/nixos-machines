# Courtesy of
#
# 1. IOHK: https://github.com/input-output-hk/ci-ops/blob/2587a1a807ecd19dd33b69557f9c6b33c15b509c/modules/hydra-master-main.nix
#
# 2. KJ Orbekk: https://git.orbekk.com/nixos-config.git/tree/config/hydra.nix

{
  imports = [
    ../base/container.nix
  ];

  config = {

    networking = {
      hostName = "fortress";
    };
  };
}
