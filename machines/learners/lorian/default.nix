# The machine "lorian" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./jupyter-lab.nix
    ../common.nix
    ../cassandra.nix
    ../../../users/xin.nix
  ];

  config = {
    networking = {
      hostName = "lorian";
      hostId = "8e549b2e";
    };

    # The LLM server — vLLM serving an OpenAI-compatible API on :8000,
    # tensor-parallel across both RTX 5090s. FP8 variant from Qwen fits
    # comfortably on 2× 32GB, leaving generous KV-cache headroom for the
    # model's native 262K context. Tool/reasoning parsers per the official
    # vLLM recipe (recipes.vllm.ai/Qwen/Qwen3.6-27B).
    services.vllm.instances.main = {
      model = "Qwen/Qwen3.6-27B-FP8";
      tensorParallelSize = 2;
      gpuMemoryUtilization = 0.90;
      maxModelLen = 262144;
      toolCallParser = "qwen3_coder";
      reasoningParser = "qwen3";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?
    home-manager.users."breakds".home.stateVersion = "25.05";
  };
}
