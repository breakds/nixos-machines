# The machine "lorian" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
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
    # tensor-parallel across both RTX 5090s. NVFP4 weights (~13.5 GB total
    # vs ~27 GB at FP8) free up the KV pool to ~41 GB; with FP8 KV cache
    # and Qwen 3.6's hybrid attention (16/64 layers on the scaling path),
    # that's ~6 concurrent 200K agents.
    #
    # `sakamakismile/Qwen3.6-27B-NVFP4` is the canonical community NVFP4
    # release (compressed-tensors format, auto-detected — no
    # --quantization flag needed). NVIDIA / RedHat don't publish a dense
    # 27B NVFP4. Tool/reasoning parsers per the official vLLM recipe.
    services.vllm.instances.main = {
      model = "sakamakismile/Qwen3.6-27B-NVFP4";
      tensorParallelSize = 2;
      gpuMemoryUtilization = 0.90;
      maxModelLen = 262144;
      toolCallParser = "qwen3_coder";
      reasoningParser = "qwen3";
      extraArgs = [
        "--kv-cache-dtype" "fp8_e4m3"
        "--trust-remote-code"
      ];
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
