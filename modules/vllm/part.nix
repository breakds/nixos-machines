{ inputs, ... }:

{
  flake.nixosModules = {
    vllm = { config, lib, pkgs, ... }:
      let
        cfg = config.services.vllm;

        instanceModule = { name, config, ... }: {
          options = {
            enable = lib.mkEnableOption "this vLLM instance" // { default = true; };

            model = lib.mkOption {
              type = lib.types.str;
              description = "HuggingFace model ID or local path to serve.";
              example = "Qwen/Qwen3-32B-AWQ";
            };

            host = lib.mkOption {
              type = lib.types.str;
              default = "0.0.0.0";
              description = "Host address to bind to.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 8000;
              description = "Port for the OpenAI-compatible API server.";
            };

            openFirewall = lib.mkOption {
              type = lib.types.bool;
              default = config.host == "0.0.0.0";
              description = "Open the firewall for this instance's port.";
            };

            autoStart = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Start this instance automatically on boot.";
            };

            tensorParallelSize = lib.mkOption {
              type = lib.types.ints.positive;
              default = 1;
              description = ''
                Number of GPUs to shard the model across (tensor parallel).
                With TP > 1, vLLM uses NCCL all-reduce on the per-layer hot
                path; colocated GPUs on the same PCIe root complex give the
                best throughput (no NVLink on consumer Blackwell).
              '';
            };

            gpuMemoryUtilization = lib.mkOption {
              type = lib.types.float;
              default = 0.90;
              description = ''
                Fraction of each GPU's memory to reserve for weights + KV
                cache. Higher = more concurrent requests / longer context,
                but less headroom for activation spikes.
              '';
            };

            maxModelLen = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = ''
                Maximum context length (tokens). Null uses the model's
                native max — vLLM will clip automatically if memory budget
                (gpuMemoryUtilization) can't fit it.
              '';
            };

            toolCallParser = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "hermes";
              description = ''
                Tool/function-calling parser. When set, also enables
                --enable-auto-tool-choice. Common values: "hermes",
                "qwen3_coder", "llama3_json".
              '';
            };

            reasoningParser = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "qwen3";
              description = ''
                Reasoning/thinking parser for chain-of-thought models.
                Common values: "qwen3", "deepseek_r1".
              '';
            };

            enforceEager = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Disable CUDA graph compilation. Defaults to false on
                discrete GPUs; set true only if you hit illegal-instruction
                crashes with a specific quantization (a workaround that
                originally surfaced on DGX Spark / SM121).
              '';
            };

            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Systemd EnvironmentFile path — typically used to inject
                HF_TOKEN for gated models. Keep outside /nix/store
                (e.g. an agenix secret or a 0600 root-owned file).
              '';
            };

            extraArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Additional command-line arguments for `vllm serve`.";
            };
          };
        };

        enabledInstances = lib.filterAttrs (_: inst: inst.enable) cfg.instances;
        instanceNames = lib.attrNames enabledInstances;

        mkService = name: inst:
          let
            otherNames = lib.filter (n: n != name) instanceNames;
            args = [
              "serve"
              inst.model
              "--host" inst.host
              "--port" (toString inst.port)
              "--gpu-memory-utilization" (toString inst.gpuMemoryUtilization)
              "--tensor-parallel-size" (toString inst.tensorParallelSize)
            ]
            ++ lib.optionals (inst.maxModelLen != null) [
              "--max-model-len" (toString inst.maxModelLen)
            ]
            ++ lib.optionals (inst.toolCallParser != null) [
              "--enable-auto-tool-choice"
              "--tool-call-parser" inst.toolCallParser
            ]
            ++ lib.optionals (inst.reasoningParser != null) [
              "--reasoning-parser" inst.reasoningParser
            ]
            ++ lib.optional inst.enforceEager "--enforce-eager"
            ++ inst.extraArgs;
          in {
            description = "vLLM inference server (${name}: ${inst.model})";
            after = [ "network.target" ];
            wantedBy = lib.optional inst.autoStart "multi-user.target";
            # Instances share the GPU pool — only one at a time.
            conflicts = map (n: "vllm-${n}.service") otherNames;

            environment = {
              # DynamicUser leaves HOME unset; libraries that default their
              # cache to ~/.foo (triton, torch inductor, transformers, etc.)
              # then fall back to "/" — which ProtectSystem=strict makes
              # read-only. Anchor HOME inside the state dir so every cache
              # lands somewhere writable, and pin the most common offenders
              # explicitly.
              HOME = "%S/vllm";
              HF_HOME = "%S/vllm/huggingface";
              TRITON_CACHE_DIR = "%S/vllm/triton";
              XDG_CACHE_HOME = "%S/vllm/cache";
              # Make /etc/vllm discoverable on sys.path so the sitecustomize.py
              # below (which chmods triton's compiled .so files) loads at
              # Python startup.
              PYTHONPATH = "/etc/vllm";
              # Disable vLLM's anonymous usage telemetry.
              VLLM_NO_USAGE_STATS = "1";
              DO_NOT_TRACK = "1";
            };

            serviceConfig = {
              Type = "exec";
              ExecStart = "${pkgs.vllm}/bin/vllm ${lib.escapeShellArgs args}";
              Restart = "on-failure";
              RestartSec = 10;
              # Model loading + first-time compile can take several minutes.
              TimeoutStartSec = "30min";

              DynamicUser = true;
              StateDirectory = "vllm";
              StateDirectoryMode = "0750";
              WorkingDirectory = "%S/vllm";

              # CUDA device access — same character-device allowlist that
              # nixpkgs's services.ollama uses. PrivateDevices=false is
              # required for /dev/nvidia* to appear in the unit's namespace.
              DeviceAllow = [
                "char-nvidiactl"
                "char-nvidia-caps"
                "char-nvidia-frontend"
                "char-nvidia-uvm"
              ];
              DevicePolicy = "closed";
              PrivateDevices = false;
              SupplementaryGroups = [ "render" "video" ];

              # General hardening (mirrors nixpkgs ollama).
              CapabilityBoundingSet = [ "" ];
              LockPersonality = true;
              NoNewPrivileges = true;
              PrivateTmp = true;
              PrivateUsers = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectSystem = "strict";
              RemoveIPC = true;
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
              SystemCallArchitectures = "native";
              SystemCallFilter = [ "@system-service" "~@privileged" ];
              UMask = "0077";
            }
            // lib.optionalAttrs (inst.environmentFile != null) {
              EnvironmentFile = inst.environmentFile;
            };
          };
      in {
        options.services.vllm = {
          instances = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule instanceModule);
            default = { };
            description = ''
              Named vLLM inference server instances. Each becomes a systemd
              service `vllm-<name>.service`. Instances declare mutual
              `conflicts` so only one runs at a time on a shared GPU pool.
            '';
          };
        };

        config = lib.mkIf (enabledInstances != { }) {
          environment.systemPackages = [ pkgs.vllm ];

          # Triton's FileCacheManager.put() writes JIT-compiled `.so`
          # files via Python's open(), which uses mode 0o666 — combined
          # with the unit's UMask=0077 that yields 0o600 (no execute
          # bit), so the subsequent dlopen fails with "failed to map
          # segment from shared object". Triton has no chmod step (see
          # python-triton/python/triton/runtime/cache.py).
          #
          # Fixing this in nixpkgs' triton derivation would force a
          # rebuild of triton + torch + torchaudio + torchvision + vllm.
          # Avoid the cascade with a `sitecustomize.py` that monkey-
          # patches FileCacheManager.put at Python startup. Python's
          # site module imports the first `sitecustomize` it finds on
          # sys.path; putting this dir on PYTHONPATH in the unit ensures
          # it loads before any triton import in either the main
          # process or the registry-inspector subprocess.
          environment.etc."vllm/sitecustomize.py".text = ''
            import os
            try:
                from triton.runtime.cache import FileCacheManager
                _orig_put = FileCacheManager.put
                def _put_then_chmod(self, data, filename, binary=True):
                    path = _orig_put(self, data, filename, binary=binary)
                    try:
                        os.chmod(path, 0o755)
                    except OSError:
                        pass
                    return path
                FileCacheManager.put = _put_then_chmod
            except ImportError:
                pass
          '';

          networking.firewall.allowedTCPPorts = lib.unique (
            lib.mapAttrsToList (_: inst: inst.port)
              (lib.filterAttrs (_: inst: inst.openFirewall) enabledInstances)
          );

          systemd.services = lib.mapAttrs'
            (name: inst: lib.nameValuePair "vllm-${name}" (mkService name inst))
            enabledInstances;
        };
      };
  };
}
