{ inputs, ... }:

# vLLM NixOS module — services.vllm.instances.<name>.
#
# The shape of this file is unusual for a "Python webserver" service: a
# merged CUDA toolkit symlinkJoin, an /etc-shipped sitecustomize.py with
# a triton monkey-patch, `path = [bash, gcc-wrapper, ninja, cuda_nvcc]`,
# a stripped-down systemd sandbox, and a `ExecPaths=/var/lib/vllm`. Each
# of those is here because vLLM 0.20 + flashinfer + triton + torch.compile
# all run a C++/CUDA JIT compiler *at process startup* to materialize
# kernels that aren't AOT-compiled for the host arch (sm_120 in our
# case). On a NixOS host they collectively assume a traditional
# /usr/local/cuda + /bin/sh shape that nixpkgs doesn't ship by default.
#
# Layers that surfaced during the lorian bring-up, all individually
# documented at their respective lines below:
#
#   1. Inspector subprocess env wipe — vllm's `_run_in_subprocess` in
#      registry.py replaces env entirely with `{PYTHONPATH: …}`, dropping
#      HOME / CUDA_HOME / TRITON_CACHE_DIR / XDG_CACHE_HOME on the way
#      into the child. Fixed by the 0003 patch in pkgs/vllm/, which
#      merges os.environ instead of replacing it.
#
#   2. Triton write-fail on `/.triton` — DynamicUser leaves HOME empty,
#      triton's cache code constructs `~/.triton/cache` and tries to
#      mkdir `/.triton`. Anchored HOME / TRITON_CACHE_DIR / XDG_CACHE_HOME
#      under %S/vllm so the cache lands in the writable state dir.
#
#   3. dlopen of triton's compiled .so fails with mmap PROT_EXEC EACCES —
#      UMask=0077 made Python's `open()` create the file mode 0o600 (no
#      exec). triton itself has no chmod step. Patched at runtime via a
#      tiny sitecustomize.py monkey-patch on FileCacheManager.put.
#
#   4. DynamicUser+StateDirectory bind-mounts %S/vllm with `noexec` by
#      default — even with the file mode fixed, the mount-level noexec
#      still rejects PROT_EXEC. Exempted via ExecPaths=/var/lib/vllm.
#
#   5. gloo's interface enumeration opens AF_NETLINK — the default
#      RestrictAddressFamilies list didn't include it. (Moot after we
#      stripped the broad systemd hardening, but worth noting because
#      it's not obvious from the error string.)
#
#   6. flashinfer JIT (sm_120 NVFP4 GEMM, FP8-KV attention) requires a
#      full C/C++ toolchain on PATH — `which`, `nvcc`, `gcc-wrapper`,
#      `ninja`, and crucially **bash** (ninja does posix_spawnp("sh"),
#      not /bin/sh; without `sh` on PATH it fails with the maddening
#      generic message `posix_spawn: No such file or directory`).
#
#   7. flashinfer's generated build.ninja uses `-isystem $CUDA_HOME/include`
#      and `-L$CUDA_HOME/lib64`, assuming the traditional unified-tree
#      layout. cuda_nvcc alone doesn't have cuda_runtime.h or libcudart.
#      Solved by pointing CUDA_HOME at a symlinkJoin of cudatoolkit +
#      cudnn.{lib,include} with a `lib64 -> lib` symlink on top.
#
#   8. dgx-spark's vllm module avoided all of (1)–(7) by running with
#      enforceEager=true + int4 quantization, which routes around the
#      JIT paths entirely. We can't — NVFP4 + CUDA graphs are the point.
#
# If a future contributor is tempted to "simplify" this module by
# matching the nixpkgs-ollama hardening pattern: please don't, or be
# ready to re-derive all the above one error message at a time.
{
  flake.nixosModules = {
    vllm = { config, lib, pkgs, ... }:
      let
        cfg = config.services.vllm;

        # nixpkgs splits the CUDA toolkit into ~30 derivations
        # (cuda_nvcc, cuda_cudart, libcublas, ...). `cudaPackages.cudatoolkit`
        # is nixpkgs' canonical unified tree — same one torch's
        # default.nix references. We use *unstable's* cudaPackages here
        # because that's what vllm itself was built against (see
        # pkgs/vllm-overlay.nix: `cudaPackages = prev.cudaPackages_13_2`
        # applied to the unstable import).
        #
        # cudnn isn't bundled into cudatoolkit (separate proprietary
        # license tarball), so layer it on. Then add the lib64→lib
        # symlink: nixpkgs CUDA libs live under lib/, but flashinfer's
        # generated build.ninja hardcodes `-L$CUDA_HOME/lib64`.
        cudaToolkit = pkgs.symlinkJoin {
          name = "vllm-cuda-toolkit";
          paths = with pkgs.unstable.cudaPackages; [
            cudatoolkit
            # cudnn's `out` output is empty (just license/nix-support);
            # its libraries and headers live in split outputs.
            cudnn.lib
            cudnn.include
          ];
          postBuild = "ln -s lib $out/lib64";
        };

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

            # vLLM/flashinfer JIT-compile CUDA kernels at runtime for
            # archs that don't ship as AOT cubin (sm_120 NVFP4 GEMM and
            # FP8-KV attention prefill are the live cases). That
            # compilation path needs a real C++ toolchain on the unit's
            # PATH, not just nvcc:
            #
            #   - pkgs.which        : `which nvcc` lookups inside torch
            #   - cudaToolkit       : merged CUDA tree (nvcc + cudart +
            #                         cublas + cudnn + ...) — flashinfer
            #                         needs `$CUDA_HOME/include/cuda_runtime.h`
            #                         and `$CUDA_HOME/lib64/libcudart.so`,
            #                         not just nvcc
            #   - backendStdenv.cc  : the CUDA-paired gcc wrapper
            #                         (provides cc/gcc/g++/c++/ld/ar);
            #                         matches the toolchain vllm was
            #                         built against
            #   - pkgs.ninja        : flashinfer builds via ninja
            #   - pkgs.bash         : ninja wraps every command in
            #                         `sh -c "..."` and looks up bare
            #                         `sh` via PATH (NOT /bin/sh).
            #                         Without bash on PATH ninja fails
            #                         with the generic
            #                         `posix_spawn: No such file or
            #                         directory` — strace identifies
            #                         "sh" as the missing exec target.
            path = [
              pkgs.which
              cudaToolkit
              pkgs.unstable.cudaPackages.backendStdenv.cc
              pkgs.ninja
              pkgs.bash
            ];

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
              # CUDA_HOME points at the merged toolkit so that both
              # torch's `$CUDA_HOME/bin/nvcc` lookup and flashinfer's
              # `-isystem $CUDA_HOME/include` + `-L$CUDA_HOME/lib64`
              # JIT compile flags both resolve.
              CUDA_HOME = "${cudaToolkit}";
              # HuggingFace's xet (content-addressed transfer) client wedges
              # mid-download for large models on this host — threads stay
              # alive, but the CAS chunk requests stop progressing and no
              # retry fires. Fall back to plain HTTP downloads.
              HF_HUB_DISABLE_XET = "1";
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

              # vLLM's runtime is a JIT compiler that happens to also serve
              # inference (torch.compile, triton kernel JIT, flashinfer
              # cutlass-NVFP4 build). Aggressive systemd hardening fights
              # this at every layer — we previously trapped /.triton write,
              # bind-mount noexec, AF_NETLINK, missing toolchain, etc.,
              # each one a separate fix. graham33/nixos-dgx-spark runs
              # this service as root with no sandbox at all for the same
              # reason. We keep the bits that don't conflict and drop the
              # rest.
              DynamicUser = true;
              StateDirectory = "vllm";
              StateDirectoryMode = "0750";
              WorkingDirectory = "%S/vllm";
              NoNewPrivileges = true;
              UMask = "0077";
              # DynamicUser+StateDirectory bind-mounts /var/lib/vllm with
              # nosuid,nodev,noexec; that conflicts with triton/flashinfer
              # dlopen'ing their own JIT-compiled .so files. Whitelist
              # the state dir for execution.
              ExecPaths = [ "/var/lib/vllm" ];

              # CUDA device access — character-device allowlist matching
              # nixpkgs's services.ollama. PrivateDevices=false is
              # required for /dev/nvidia* to appear in the unit's
              # namespace at all.
              DeviceAllow = [
                "char-nvidiactl"
                "char-nvidia-caps"
                "char-nvidia-frontend"
                "char-nvidia-uvm"
              ];
              DevicePolicy = "closed";
              PrivateDevices = false;
              SupplementaryGroups = [ "render" "video" ];
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
          # with this unit's UMask=0077 the file ends up 0o600 (no
          # execute bit for owner), so the subsequent dlopen fails with
          # mmap(PROT_EXEC) → EACCES. Triton has no chmod step (see
          # python-triton/python/triton/runtime/cache.py upstream).
          #
          # Patching triton in nixpkgs would cascade rebuilds through
          # triton → torch → torchaudio → torchvision → vllm. Avoid that
          # with a sitecustomize.py shipped via /etc and discoverable via
          # PYTHONPATH=/etc/vllm in the unit env. Python's site module
          # imports the first sitecustomize it finds on sys.path, so the
          # monkey-patch lands in both the main vLLM process and the
          # registry-inspector subprocess.
          #
          # Pair with `ExecPaths=/var/lib/vllm` in the unit — that's the
          # other half of the fix (lifts the noexec the DynamicUser state
          # bind mount applies by default).
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
