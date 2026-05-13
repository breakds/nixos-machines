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
  dlpack = final.callPackage ./dlpack {};

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {

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
    })
  ];
}
