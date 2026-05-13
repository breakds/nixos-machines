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
    services.vllm.gpuTargets = [ "12.0" ];

    # CUDA 13.2 (vllm toolkit) emits PTX 8.8 — newer than the embedded
    # PTX-to-SASS compiler in stable nixpkgs's R580.142 driver, which
    # tops out at the 13.0 / PTX 8.7 envelope. Surfaces as
    # cudaErrorUnsupportedPtxVersion inside vllm-flash-attn's prebuilt
    # ViT kernels during profile_run.
    #
    # NVIDIA's CUDA 13.2 GA bundles R595.x as the recommended driver
    # (NVIDIA CUDA Toolkit Release Notes, Table 3). nixpkgs unstable
    # already has R595.71.05 in its `linuxPackages.nvidiaPackages.production`
    # set; pull it via `linuxKernel.packagesFor` so unstable's nvidia
    # source builds against our host kernel (still on stable 25.05 →
    # Linux 7.0.3) instead of unstable's default 6.18.
    hardware.nvidia.package =
      (pkgs.unstable.linuxKernel.packagesFor config.boot.kernelPackages.kernel)
      .nvidiaPackages.production;

    # The LLM server — vLLM serving an OpenAI-compatible API on :8000,
    # tensor-parallel across both RTX 5090s. NVFP4 weights (~13.5 GB total
    # vs ~27 GB at FP8) free up the KV pool to ~41 GB; with FP8 KV cache
    # and Qwen 3.6's hybrid attention (Gated DeltaNet + Gated Attention,
    # 16/64 layers on the scaling path), that's ~6 concurrent 200K agents.
    #
    # `unsloth/Qwen3.6-27B-NVFP4` repacks the NVFP4 scales in a layout
    # vLLM's compressed-tensors loader recognizes (auto-detected — no
    # --quantization flag needed). The Qwen3.5/3.6 architecture
    # (`Qwen3_5ForConditionalGeneration`) is implemented natively in
    # vllm 0.20.2 (vllm/model_executor/models/qwen3_5.py), so
    # --trust-remote-code is not load-bearing for the model class itself —
    # it's kept because the upstream recipe specifies it and it harmlessly
    # also covers any tokenizer/processor code paths.
    #
    # --max-num-seqs caps concurrent requests so the activation-VRAM
    # spikes during prefill stay bounded; tune up if requests queue.
    services.vllm.instances.main = {
      model = "unsloth/Qwen3.6-27B-NVFP4";
      tensorParallelSize = 2;
      gpuMemoryUtilization = 0.90;
      maxModelLen = 200000;
      toolCallParser = "qwen3_coder";
      reasoningParser = "qwen3";
      extraArgs = [
        "--kv-cache-dtype" "fp8_e4m3"
        "--dtype" "bfloat16"
        "--max-num-seqs" "8"
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
