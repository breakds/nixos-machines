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

    # 2× RTX 5090 (Blackwell consumer) → sm_120 only.
    vital.vllm.gpuTargets = [ "12.0" ];

    # The LLM server — vLLM serving an OpenAI-compatible API on :8000,
    # tensor-parallel across both RTX 5090s.
    #
    # Qwen3-32B AWQ (INT4 weights) fits comfortably on 2× 32 GB: ~18 GB
    # weights total, ~9 GB per GPU at TP=2, leaving ~20 GB per GPU for KV
    # cache at gpu-memory-utilization 0.90. FP8 KV cache stretches that
    # significantly further.
    #
    # NOTE: previously pointed at sakamakismile/Qwen3.6-27B-NVFP4, but
    # that checkpoint declares architectures = ["Qwen3_5ForConditionalGeneration"]
    # which is not registered in vLLM 0.20.2 (vllm-project/vllm#35391 —
    # support landed post-0.20). Unsloth's NVFP4 build has the same
    # config.json arch and ships no `auto_map`/custom modeling code, so
    # --trust-remote-code can't bridge it. Move back to NVFP4 + Qwen 3.6
    # once vLLM is bumped to a release with Qwen3.5/3.6 support.
    services.vllm.instances.main = {
      model = "Qwen/Qwen3-32B-AWQ";
      tensorParallelSize = 2;
      gpuMemoryUtilization = 0.90;
      toolCallParser = "qwen3_coder";
      reasoningParser = "qwen3";
      extraArgs = [
        "--kv-cache-dtype" "fp8_e4m3"
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
