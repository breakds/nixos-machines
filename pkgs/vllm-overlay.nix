# Overlay providing vllm 0.20.2 + the CUDA-13 / Python-package adjustments
# it requires.
#
# Applied to nixpkgs-unstable (the CUDA-aware ML tree this repo already uses
# for ollama, stt-server, etc.). Switches cudaPackages to 13.2 — required for
# stable NVFP4 weight quantization on sm_120 (RTX 50-series consumer
# Blackwell). The 0.19 → 0.20.2 vLLM bump also covers the signed-scale
# Marlin-kernel fix and the SM 12.0 kernel-selection improvements that 0.19
# was missing.
#
# CUDA-13-driven fixes derived from graham33/nixos-dgx-spark's overlays/
# fixes.nix; aarch64-only and CPU/ROCm-only fixes from that file are skipped.
final: prev: {
  # Global CUDA toolkit switch. Affects every consumer that reads
  # `pkgs.cudaPackages` from the unstable import (torch, ollama, etc).
  # 13.2 already ships nccl 2.28.7 with Blackwell sm_120 support, so the
  # manual nccl bump that was needed under CUDA 12.9 is gone.
  cudaPackages = prev.cudaPackages_13_2;

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

      # vllm itself: still target sm_120 only (Blackwell consumer).
      # MAX_JOBS caps build parallelism — nvcc/cicc uses ~6 GiB per job, so
      # 16 on lorian (16C/32T, 256 GiB) leaves comfortable headroom.
      vllm = (python-final.callPackage ./vllm {
        inherit (final) cudaPackages;
        gpuTargets = [ "12.0" ];
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
