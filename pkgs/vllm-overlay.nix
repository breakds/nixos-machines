# Overlay providing vllm 0.20.2 + the CUDA-13 / Python-package adjustments
# it requires.
#
# Applied to nixpkgs-unstable (the CUDA-aware ML tree this repo already uses
# for ollama, stt-server, etc.). Switches cudaPackages to 13.0 — the NVIDIA
# driver currently in nixpkgs unstable is 580.142, whose embedded PTX
# compiler only supports up to CUDA 13.0's PTX version. CUDA 13.2 emits
# newer PTX (8.8) which trips cudaErrorUnsupportedPtxVersion at runtime
# inside vllm-flash-attn's prebuilt ViT kernels. Stay on 13.0 until a
# newer R580.x or R590 driver lands. NVFP4 support is in 13.0; 13.2 had
# stability improvements we lose, but they're moot if nothing loads.
# The 0.19 → 0.20.2 vLLM bump also covers the signed-scale Marlin-kernel
# fix and the SM 12.0 kernel-selection improvements that 0.19 was missing.
#
# CUDA-13-driven fixes derived from graham33/nixos-dgx-spark's overlays/
# fixes.nix; aarch64-only and CPU/ROCm-only fixes from that file are skipped.
#
# `gpuTargets` is the per-host CUDA compute-capability list vLLM compiles
# kernels for — typically the single arch of the GPUs on that machine
# (e.g. ["12.0"] on a 5090 host, ["8.9"] on a 4090 host). Empty falls
# back to nixpkgs' system-wide `cudaCapabilities`, which works but wastes
# build time compiling kernels the host can't run.
{ gpuTargets ? [ ] }:

final: prev: {
  # Global CUDA toolkit switch. Affects every consumer that reads
  # `pkgs.cudaPackages` from the unstable import (torch, ollama, etc).
  # 13.0 already ships nccl 2.28.7 with Blackwell sm_120 support, so the
  # manual nccl bump that was needed under CUDA 12.9 is gone.
  cudaPackages = prev.cudaPackages_13_0;

  # OpenCV's CUDA backend doesn't compile under CUDA 13; vLLM doesn't need
  # CUDA-accelerated OpenCV anyway (uses opencv-python-headless for image
  # preprocessing).
  opencv4 = prev.opencv4.override { enableCuda = false; };

  # Header-only tensor-sharing lib pulled in transitively by torch/cupy
  # under CUDA 13. Not in nixpkgs.
  dlpack = prev.stdenv.mkDerivation rec {
    pname = "dlpack";
    version = "1.2";
    src = prev.fetchFromGitHub {
      owner = "dmlc";
      repo = "dlpack";
      rev = "v${version}";
      hash = "sha256-9sKjRGnoaHLUXjDahyWrYYYdDQuqwJyL0hFo1YhGov4=";
    };
    nativeBuildInputs = [ prev.cmake ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/include
      cp -r $src/include/dlpack $out/include/
    '';
    meta = with prev.lib; {
      description = "Open in-memory tensor structure for sharing tensors among frameworks";
      homepage = "https://github.com/dmlc/dlpack";
      license = licenses.asl20;
      platforms = platforms.all;
    };
  };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      # Not yet in nixpkgs.
      opentelemetry-semantic-conventions-ai =
        python-final.callPackage ./opentelemetry-semantic-conventions-ai { };

      # CUDA 13: upstream marks torch broken (needs validation cycle to lift).
      torch = python-prev.torch.overridePythonAttrs (oldAttrs: {
        meta = oldAttrs.meta // { broken = false; };
      });

      # CUDA 13 split the CUDA C runtime headers into a separate package
      # (cuda_crt). bitsandbytes' build needs them on the include path.
      bitsandbytes = python-prev.bitsandbytes.overridePythonAttrs
        (oldAttrs: prev.lib.optionalAttrs (final.cudaPackages ? cuda_crt) {
          buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
            final.cudaPackages.cuda_crt
          ];
        });

      # cupy in nixpkgs hard-codes cuDNN 8.9.7 (gone in CUDA 13). Re-thread
      # cudaPackages from the overlay so it picks up our 13.2 cudnn 9.x.
      cupy = python-prev.cupy.override {
        cudaPackages = final.cudaPackages;
      };

      # vllm 0.20 imports `mistral_common[image]` which only exists from
      # 1.11.0 onward; nixpkgs has 1.8.8.
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

      # vllm itself, narrowed to the per-host `gpuTargets`.
      # MAX_JOBS caps build parallelism — nvcc/cicc uses ~6 GiB per job, so
      # 16 on lorian (16C/32T, 256 GiB) leaves comfortable headroom.
      vllm = (python-final.callPackage ./vllm {
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
}
