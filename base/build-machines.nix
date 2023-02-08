{ config, pkgs, lib, ... }:

{
  # Just in case you want to add localhost as one of the build
  # machines as well, put the following code in your configuration
  #
  # nix.buildMachines = {
  #   hostName = "localhost";
  #   systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
  #   maxJobs = lib.mkDefault 12;
  #   speedFactor = lib.mkDefault 2;
  #   supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ]; 
  # }
  #
  # You will need to decide the max jobs and speed factor.
  config = {
    nix = {
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "octavian.local";
          systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
          maxJobs = 12;
          speedFactor = 6;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
        {
          hostName = "malenia.local";
          systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
          maxJobs = 24;
          speedFactor = 8;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
        }
        {
          hostName = "localhost";
          systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
          maxJobs = lib.mkDefault 12;
          speedFactor = lib.mkDefault 2;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ]; 
        }
      ];
      settings = {
        trusted-substituters = [
          "ssh://richelieu.local"
          "ssh://malenia.local"
        ];
      };
    };
  };
}
