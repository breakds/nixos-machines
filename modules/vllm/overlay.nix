# Overlay providing vllm 0.28.0, its Python dependency pins, and the
# `vllm-with-batteries` wrapper that bundles the runtime CUDA toolchain
# JIT-compiled kernels need (flashinfer, triton).
#
# Applied via modules/vllm/default.nix only on machines that run vllm —
# the opentelemetry / flashinfer pins shouldn't land tree-wide just
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

      # vLLM 0.28.0 needs xgrammar >= 0.2.1; nixpkgs ships 0.1.33, on master
      # too. The gap is not cosmetic — 0.1.33 lacks `normalize_tool_choice`,
      # `get_model_structural_tag` and the whole `openai_tool_call_schema`
      # module, all of which vLLM imports. pythonRelaxDeps drops vLLM's pin,
      # so each one surfaces as a crash at startup instead.
      #
      # 0.2.x replaced nanobind with its own cpp/tvm_ffi bindings, so nixpkgs'
      # nanobind patch is obsolete and apache-tvm-ffi joins the build. The
      # transformers < 5 bound is upstream being careful about remote-code
      # tokenizers (internlm2_5, aya-23, deepseek-coder-v1.5); 0.2.6 drops it
      # entirely, and Qwen3.8 is not affected, so relax it rather than hold
      # transformers back for vLLM's sake.
      xgrammar = (python-prev.xgrammar.overridePythonAttrs (oldAttrs: rec {
        version = "0.2.5";
        src = prev.fetchFromGitHub {
          owner = "mlc-ai";
          repo = "xgrammar";
          tag = "v${version}";
          fetchSubmodules = true;
          hash = "sha256-DvQizGr4YmMY+6Tl8PiCNmYkOk6d3mW/OwS25/ifxyI=";
        };

        patches = [ ];

        build-system = [
          prev.cmake
          prev.ninja
          python-final.scikit-build-core
          python-final.apache-tvm-ffi
        ];

        dependencies = (oldAttrs.dependencies or [ ]) ++ [
          python-final.apache-tvm-ffi
          python-final.typing-extensions
        ];

        pythonRelaxDeps = [ "transformers" ];

        # The 0.2.x suite pulls tokenizers from HuggingFace at runtime, which
        # the sandbox has no network for.
        doCheck = false;
      }));

      # vLLM 0.28.0 pins flashinfer-python 0.6.16.post3 and calls APIs from it,
      # including fp8 KV-cache scale plumbing (`kv_cache_sf`) in prefill. nixpkgs
      # ships 0.6.4, which starts but fails under benchmark load with that argument.
      flashinfer-python = (python-prev.flashinfer-python.override {
        buildPythonPackage = python-final.buildPythonPackage.override {
          inherit (python-final.torch) stdenv;
        };
      }).overridePythonAttrs (oldAttrs: rec {
        version = "0.6.16.post3";
        __structuredAttrs = true;
        src = prev.fetchFromGitHub {
          owner = "flashinfer-ai";
          repo = "flashinfer";
          tag = "v${version}";
          fetchSubmodules = true;
          hash = "sha256-mhmjIX1Whats3JUjrMr27mY7o3DR4D/Wg5XCJrFHqEY=";
        };

        build-system = (oldAttrs.build-system or [ ]) ++ [
          python-final.packaging
        ];

        pythonRemoveDeps = builtins.filter
          (dep: dep != "nvidia-cutlass-dsl")
          ((oldAttrs.pythonRemoveDeps or [ ]) ++ [
          # cuda-python and nccl4py are runtime deps of FlashInfer's moe_ep
          # expert-parallel transport, which a dense model never reaches
          # (FlashInfer's own requirements.txt says as much). nixpkgs has no
          # cuda-python at all, and its nccl4py is broken — the package
          # patches nccl_ep_linux.pyx, which does not exist at the 0.4.1 tag.
          "cuda-python"
          "nccl4py"
          # Not needed for the vLLM CUDA attention path we use.
          "cuda-tile"
          ]);

        # nixpkgs' dependency list was written for 0.6.4; ninja is one of the
        # few genuinely new entries in 0.6.16's requirements.txt.
        dependencies = (oldAttrs.dependencies or [ ]) ++ [
          python-final.ninja
          python-final.nvidia-cutlass-dsl
          python-final.packaging
          python-final.requests
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
