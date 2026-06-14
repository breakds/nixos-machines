# Overlay providing vllm 0.23.0, its Python dependency pins, and the
# `vllm-with-batteries` wrapper that bundles the runtime CUDA toolchain
# JIT-compiled kernels need (flashinfer, triton).
#
# Applied via modules/vllm/default.nix only on machines that run vllm —
# the opentelemetry / mistral-common pins shouldn't land tree-wide just
# because a host happens to have a GPU. The CUDA 13.2 bump and its
# tree-wide consumers (torch, cupy, bitsandbytes, opencv) live in
# pkgs/cuda-13-overlay.nix and apply to every host using the unstable
# pkgs scope.
#
# `gpuTargets` is the per-host CUDA compute-capability list vLLM compiles
# kernels for — typically the single arch of the GPUs on that machine
# (e.g. ["12.0"] on a 5090 host, ["8.9"] on a 4090 host). Empty falls
# back to nixpkgs' system-wide `cudaCapabilities`, which still builds
# but wastes time compiling kernels the host can't run.
{ gpuTargets ? [ ] }:

final: prev:
let
  runtimeCudaToolkit = final.symlinkJoin {
    name = "vllm-cuda-toolkit-${final.cudaPackages.cudaMajorMinorVersion}";
    paths = with final.cudaPackages; [
      cudatoolkit
      cudnn.lib
      cudnn.include
    ];
    postBuild = "ln -s lib $out/lib64";
  };
in {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      # Not yet in nixpkgs.
      opentelemetry-semantic-conventions-ai =
        python-final.callPackage ../../pkgs/opentelemetry-semantic-conventions-ai { };

      # vllm imports `mistral_common[image]`, which only exists from
      # 1.11.0 onward; keep this scoped to vLLM until nixpkgs catches up.
      mistral-common = python-prev.mistral-common.overridePythonAttrs (oldAttrs: rec {
        version = "1.11.0";
        src = prev.fetchFromGitHub {
          owner = "mistralai";
          repo = "mistral-common";
          tag = "v${version}";
          hash = "sha256-DejbLY2i6Hp1J+spxMut5RKugj7rDyrZmp6v+5wqyWY=";
        };
        # 1.11.0 adds tests that need llguidance (not yet packaged in nixpkgs).
        disabledTestPaths = (oldAttrs.disabledTestPaths or [ ]) ++ [
          "tests/guidance"
        ];
      });

      # Bump the opentelemetry stack: nixpkgs unstable still ships
      # api/sdk 1.34.0 and semconv/instrumentation 0.55b0, but
      # opentelemetry-semantic-conventions-ai 0.4.15 (above) demands
      # sdk >= 1.38 and semconv >= 0.59b0. All four packages live on
      # the same upstream release train; pin the lot to v1.40.0 / 0.61b0
      # (api+sdk+semconv share opentelemetry-python; instrumentation
      # lives in opentelemetry-python-contrib).
      opentelemetry-api = python-prev.opentelemetry-api.overridePythonAttrs (oldAttrs: rec {
        version = "1.40.0";
        src = prev.fetchFromGitHub {
          owner = "open-telemetry";
          repo = "opentelemetry-python";
          tag = "v${version}";
          hash = "sha256-1KVy9s+zjlB4w7E45PMCWRxPus24bgBmmM3k2R9d+Jg=";
        };
        sourceRoot = "${src.name}/opentelemetry-api";
      });

      opentelemetry-sdk = python-prev.opentelemetry-sdk.overridePythonAttrs (oldAttrs: rec {
        version = "1.40.0";
        src = prev.fetchFromGitHub {
          owner = "open-telemetry";
          repo = "opentelemetry-python";
          tag = "v${version}";
          hash = "sha256-1KVy9s+zjlB4w7E45PMCWRxPus24bgBmmM3k2R9d+Jg=";
        };
        sourceRoot = "${src.name}/opentelemetry-sdk";
      });

      opentelemetry-semantic-conventions =
        python-prev.opentelemetry-semantic-conventions.overridePythonAttrs (oldAttrs: rec {
          version = "0.61b0";
          src = prev.fetchFromGitHub {
            owner = "open-telemetry";
            repo = "opentelemetry-python";
            # The semconv subdir tags as 0.NNbN, not v1.x.y — but the
            # opentelemetry-python repo tags both together at v1.x.y.
            tag = "v1.40.0";
            hash = "sha256-1KVy9s+zjlB4w7E45PMCWRxPus24bgBmmM3k2R9d+Jg=";
          };
          sourceRoot = "${src.name}/opentelemetry-semantic-conventions";
        });

      opentelemetry-instrumentation =
        python-prev.opentelemetry-instrumentation.overridePythonAttrs (oldAttrs: rec {
          version = "0.61b0";
          src = prev.fetchFromGitHub {
            owner = "open-telemetry";
            repo = "opentelemetry-python-contrib";
            tag = "v${version}";
            hash = "sha256-DT13gcYPNYXBPnf622WsA16C+7sabJfOshDquHn06Ok=";
          };
          sourceRoot = "${src.name}/opentelemetry-instrumentation";
        });

      # vLLM 0.23.0 calls newer FlashInfer APIs, including fp8 KV-cache scale
      # plumbing (`kv_cache_sf`) in prefill. nixpkgs currently ships 0.6.4,
      # which starts but fails under benchmark load with that argument.
      flashinfer = python-prev.flashinfer.overridePythonAttrs (oldAttrs: rec {
        version = "0.6.12";
        src = prev.fetchFromGitHub {
          owner = "flashinfer-ai";
          repo = "flashinfer";
          tag = "v${version}";
          fetchSubmodules = true;
          hash = "sha256-n7Vl8MkKCMhvlhEWlo1rEPqL+IsA1+FsWiX/EL/VPg0=";
        };

        pythonRemoveDeps = (oldAttrs.pythonRemoveDeps or [ ]) ++ [
          # New in FlashInfer 0.6.12 metadata; not packaged in nixpkgs and not
          # needed for the vLLM CUDA attention path we use.
          "cuda-tile"
        ];
      });

      # vllm itself, narrowed to the per-host `gpuTargets`.
      # MAX_JOBS caps build parallelism — nvcc/cicc uses ~6 GiB per job, so
      # 16 on lorian (16C/32T, 256 GiB) leaves comfortable headroom.
      vllm = (python-final.callPackage ../../pkgs/vllm {
        inherit (final) cudaPackages;
        inherit gpuTargets;
        # ROCm-only args — null out for CUDA-only build.
        amd-aiter = null;
        amd-quark = null;
        amdsmi = null;
        rocmPackages = { };
        pybind11 = python-final.pybind11;
      }).overrideAttrs (old: {
        preConfigure = (old.preConfigure or "") + ''
          export MAX_JOBS=16
        '';
      });
    })
  ];

  # vLLM with the runtime CUDA/JIT "batteries" needed by flashinfer/triton
  # startup compilation. This is deliberately a lightweight wrapper around
  # `vllm`, not an override of the vLLM derivation, so changing the runtime
  # toolchain wrapper does not rebuild the CUDA extension-heavy base package.
  #
  # flashinfer's generated build.ninja assumes a traditional unified CUDA
  # layout with `$CUDA_HOME/include` and `$CUDA_HOME/lib64`, but nixpkgs splits
  # CUDA into many derivations and stores libraries under lib/. The merged
  # toolkit comes from final.cudaPackages, the same CUDA package set passed to
  # pkgs/vllm/default.nix above.
  vllm-with-batteries = final.symlinkJoin rec {
    name = "${final.vllm.name}-with-batteries";
    paths = [ final.vllm ];
    nativeBuildInputs = [ final.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vllm \
        --set CUDA_HOME ${runtimeCudaToolkit} \
        --prefix PATH : ${final.lib.makeBinPath [
          # `which nvcc` lookups inside torch.
          final.which
          # nvcc plus headers/libs in the layout expected by flashinfer.
          runtimeCudaToolkit
          # CUDA-paired gcc wrapper for runtime JIT compilation.
          final.cudaPackages.backendStdenv.cc
          # flashinfer builds via ninja.
          final.ninja
          # ninja does posix_spawnp("sh"), not /bin/sh.
          final.bash
        ]}
    '';
    passthru = (final.vllm.passthru or { }) // {
      inherit name;
      inherit runtimeCudaToolkit;
      unwrapped = final.vllm;
    };
    meta = (final.vllm.meta or { }) // {
      mainProgram = "vllm";
    };
  };
}
