# The machine "lorian" is one of the two machine learning stations.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../cassandra.nix
    ../../../users/xin.nix
    ../../../users/brent.nix
  ];

  config = {
    networking = {
      hostName = "lorian";
      hostId = "8e549b2e";
    };

    # Mitigate recurring RTX 5090 Xid 79 "fallen off the bus" events.
    # The failing device has consistently been the card at PCI 0000:61:00.0.
    #
    # Keep the PCIe link out of ASPM low-power states. This costs a little idle
    # platform power, but removes one class of link retraining / wakeup failures.
    boot.kernelParams = [ "pcie_aspm=off" ];

    # Disable NVIDIA runtime dynamic power management. On Blackwell this keeps
    # the GSP/driver away from deeper runtime power transitions that have been
    # implicated in some Xid 79 reports. Expect higher idle GPU power.
    boot.extraModprobeConfig = ''
      options nvidia NVreg_DynamicPowerManagement=0x00
    '';

    hardware.nvidia.nvidiaPersistenced = true;

    # Power limits are not persistent across reboot / driver reload, so apply
    # them declaratively after the NVIDIA devices are initialized.
    systemd.services.lorian-nvidia-power-limit = {
      description = "Apply RTX 5090 persistence mode and 450 W power limit";
      wantedBy = [ "multi-user.target" ];
      after = [ "nvidia-persistenced.service" "systemd-udev-settle.service" ];
      wants = [ "nvidia-persistenced.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pm 1
        ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 450
      '';
    };

    # Xid 79 diagnostics. The mitigations above have not stopped the card at
    # 0000:61:00.0 from periodically falling off the bus, and by the time the
    # Xid fires the GPU is electrically gone — so the journal only ever shows
    # the aftermath. These two services capture the missing evidence: what the
    # GPUs were doing in the seconds *before* the next failure, plus a full
    # system snapshot at the moment it happens.

    # Continuously sample both GPUs (temp / VRAM temp / power / clocks / PCIe
    # link) to the journal. Tolerates one GPU vanishing mid-run and keeps
    # logging the survivor. Inspect with: journalctl -u gpu-telemetry-sampler
    systemd.services.gpu-telemetry-sampler = {
      description = "Sample RTX 5090 telemetry for Xid 79 diagnosis";
      wantedBy = [ "multi-user.target" ];
      after = [ "lorian-nvidia-power-limit.service" ];
      path = [ config.hardware.nvidia.package.bin pkgs.coreutils ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;
        Nice = 10;
      };
      script = ''
        echo "CSV fields: epoch,iso8601,gpu,temp_C,vram_temp_C,power_W,plimit_W,sm_MHz,mem_MHz,util_pct,pstate,pcie_gen,pcie_width"
        while true; do
          ts=$(date +%s); iso=$(date -Is)
          rows=$(timeout 10 nvidia-smi \
            --query-gpu=index,temperature.gpu,temperature.memory,power.draw,enforced.power.limit,clocks.sm,clocks.mem,utilization.gpu,pstate,pcie.link.gen.current,pcie.link.width.current \
            --format=csv,noheader,nounits 2>/dev/null || true)
          if [ -n "$rows" ]; then
            while IFS= read -r r; do printf '%s,%s,%s\n' "$ts" "$iso" "$r"; done <<< "$rows"
          else
            printf '%s,%s,ALL_GPUS_UNREACHABLE\n' "$ts" "$iso"
          fi
          sleep 2
        done
      '';
    };

    # Watch the kernel journal and, on any NVRM Xid, dump a full system
    # snapshot (telemetry lead-up + sensors + nvidia-smi -q + PCIe link/error
    # registers) to /var/log/gpu-xid-events/xid-<epoch>.txt for offline review.
    systemd.services.gpu-xid-watch = {
      description = "Capture a full snapshot on NVIDIA Xid events";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-journald.service" ];
      path = [
        config.systemd.package config.hardware.nvidia.package.bin
        pkgs.lm_sensors pkgs.pciutils pkgs.coreutils pkgs.gnugrep
      ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;
        LogsDirectory = "gpu-xid-events";
      };
      script = ''
        last=0
        journalctl -kf -n0 -o cat | while IFS= read -r line; do
          case "$line" in
            *NVRM*Xid*) : ;;
            *) continue ;;
          esac
          now=$(date +%s)
          [ $(( now - last )) -lt 15 ] && continue
          last=$now
          f="/var/log/gpu-xid-events/xid-$now.txt"
          {
            echo "==== Xid event captured $(date -Is) ===="
            echo "Trigger: $line"
            echo; echo "---- telemetry lead-up (last 80 samples) ----"
            timeout 10 journalctl -u gpu-telemetry-sampler -n 80 -o cat 2>&1
            echo; echo "---- sensors -A ----"
            timeout 15 sensors -A 2>&1
            echo; echo "---- nvidia-smi -q ----"
            timeout 20 nvidia-smi -q 2>&1
            echo; echo "---- PCIe link / error registers ----"
            for bdf in 41:00.0 61:00.0; do
              echo "## $bdf"
              timeout 15 lspci -vvv -s "$bdf" 2>&1 \
                | grep -iE 'LnkSta|LnkCap|DevSta|UESta|CESta|Status:'
            done
            echo; echo "---- kernel tail ----"
            timeout 10 journalctl -k -n 50 -o short-precise 2>&1
          } > "$f" 2>&1
          echo "Captured Xid snapshot -> $f"
        done
      '';
    };

    # 2× RTX 5090 (Blackwell consumer) → sm_120 only.
    services.vllm.gpuTargets = [ "12.0" ];

    # The LLM server — vLLM serving an OpenAI-compatible API on :8000,
    # tensor-parallel across both RTX 5090s.
    #
    # Qwen3.8-27B keeps 3.6's `Qwen3_5ForConditionalGeneration` class, so the
    # pinned vLLM serves it with no engine change. New in 3.8: a vision
    # encoder (the model is multimodal now) and a 262144 native context. We
    # cap maxModelLen under that ceiling — a single request would otherwise be
    # allowed to claim most of the shared KV pool. 3.6 was capped at 200000.
    #
    # `unsloth/Qwen3.8-27B-NVFP4` is compressed-tensors in mixed-precision
    # format: an FP8 W8A8 group covering lm_head, plus an nvfp4-pack group for
    # the rest. Both format names are recognised by compressed-tensors 0.15.
    #
    # Picked over Inferact's ModelOpt NVFP4 build for two reasons. It declares
    # a kv_cache_scheme with calibrated static_minmax scales, so --kv-cache-dtype
    # below gets real k/v_scale values; Inferact declares none and vLLM falls
    # back to a scaling factor of 1.0, which risks accuracy under fp8_e4m3. And
    # it fits roughly twice the KV cache — about 920K tokens against 445K on
    # vLLM's own TP2 5090 measurements.
    #
    # The nominal cost is MTP acceptance, 0.788 against Inferact's 0.897 — see
    # the measured figure below, which makes that gap look smaller than it
    # reads on paper.
    #
    # --trust-remote-code is not load-bearing for the model class, which is
    # native. Kept because the upstream recipe specifies it and it harmlessly
    # covers the tokenizer/processor paths.
    #
    # --max-num-seqs caps concurrent requests so the activation-VRAM
    # spikes during prefill stay bounded; tune up if requests queue.
    #
    # --max-num-batched-tokens sets the prefill chunk. vLLM derives
    # max_num_scheduled_tokens from it and warns below 8192 once speculative
    # decoding claims its draft slots; the default 2048 meant ~110 chunks to
    # fill a 225000-token context.
    #
    # Note these two settings pull against each other. gpuMemoryUtilization
    # raises the total budget, but a larger prefill chunk makes the memory
    # profiler reserve more for activations, which comes out of the KV pool.
    # 0.9178 is vLLM's own arithmetic for restoring the effective KV size it
    # had before CUDA-graph memory profiling became the default in 0.21.
    # Watch the reported "GPU KV cache size" after changing either.
    #
    # The checkpoint ships its own MTP module. Use it as a speculative draft
    # model for faster decode without loading a separate draft checkpoint.
    # Measured acceptance is 0.73 over 3 positions (0.83 / 0.70 / 0.67), so
    # ~2.2 of every 3 drafted tokens land — worth keeping at 3.
    services.vllm.instances.main = {
      model = "unsloth/Qwen3.8-27B-NVFP4";
      tensorParallelSize = 2;
      gpuMemoryUtilization = 0.9178;
      maxModelLen = 225000;
      toolCallParser = "qwen3_coder";
      reasoningParser = "qwen3";
      extraArgs = [
        "--kv-cache-dtype" "fp8_e4m3"
        "--dtype" "bfloat16"
        "--max-num-seqs" "8"
        "--max-num-batched-tokens" "8192"
        "--trust-remote-code"
        "--speculative-config" ''{"method":"mtp","num_speculative_tokens":3}''
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
