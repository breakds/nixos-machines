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
    #
    # The upstream checkpoint now includes its own MTP module. Use it as a
    # speculative draft model for faster decode without loading a separate
    # draft checkpoint.
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
