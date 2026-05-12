{ lib
, stdenv
, python
, buildPythonPackage
, fetchFromGitHub
, symlinkJoin
, autoAddDriverRunpath
, # nativeBuildInputs
  which
, # build-system
  cmake
, grpcio-tools
, jinja2
, ninja
, packaging
, setuptools
, setuptools-scm
, # buildInputs
  onednn
, numactl
, llvmPackages
, # dependencies
  aioprometheus
, amd-aiter
, amd-quark
, amdsmi
, anthropic
, bitsandbytes
, blake3
, cachetools
, cbor2
, compressed-tensors
, datasets
, depyf
, einops
, fastapi
, gguf
, grpcio
, grpcio-reflection
, ijson
, importlib-metadata
, kaldi-native-fbank
, llguidance
, lm-format-enforcer
, mcp
, mistral-common
, model-hosting-container-standards
, msgspec
, numba
, numpy
, openai
, openai-harmony
, opencv-python-headless
, opentelemetry-api
, opentelemetry-exporter-otlp
, opentelemetry-sdk
, opentelemetry-semantic-conventions-ai
, outlines
, pandas
, partial-json-parser
, peft
, prometheus-fastapi-instrumentator
, py-cpuinfo
, pyarrow
, pybase64
, pydantic
, python-json-logger
, python-multipart
, pyzmq
, ray
, sentencepiece
, setproctitle
, tiktoken
, timm
, tokenizers
, torch
, torchaudio
, torchvision
, transformers
, uvicorn
, xformers
, xgrammar
, # linux-only
  psutil
, py-libnuma
, # cuda-only
  apache-tvm-ffi
, cupy
, flashinfer
, nvidia-ml-py
, # rocm-only
  pybind11
, # optional-dependencies
  # audio
  librosa
, soundfile
, # internal dependency - for overriding in overlays
  vllm-flash-attn ? null
, cudaSupport ? torch.cudaSupport
, cudaPackages ? { }
, rocmSupport ? torch.rocmSupport
, rocmPackages ? { }
, gpuTargets ? [ ]
,
}:

let
  inherit (lib)
    lists
    strings
    trivial
    ;

  inherit (cudaPackages) flags;

  shouldUsePkg =
    pkg: if pkg != null && lib.meta.availableOn stdenv.hostPlatform pkg then pkg else null;

  # see CMakeLists.txt, grepping for CUTLASS_REVISION
  # https://github.com/vllm-project/vllm/blob/v${version}/CMakeLists.txt
  cutlass = fetchFromGitHub {
    name = "cutlass-source";
    owner = "NVIDIA";
    repo = "cutlass";
    tag = "v4.4.2";
    hash = "sha256-0q9Ad0Z6E/rO2PdM4uQc8H0E0qs9uKc3reHepiHhjEc=";
  };

  # FlashMLA's Blackwell (SM100) kernels were developed against CUTLASS v3.9.0
  # (since https://github.com/vllm-project/FlashMLA/commit/9c5dfab6d1746b4a27af14f440e7afd5c01ece68)
  # and are currently incompatible with CUTLASS v4.x APIs. The rest of the vLLM
  # build uses a newer CUTLASS, so we package both versions.
  # See upstream issue: https://github.com/vllm-project/vllm/issues/27425
  # See git submodule commit at:
  # https://github.com/vllm-project/FlashMLA/tree/${flashmla.src.rev}/csrc
  cutlass-flashmla = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "cutlass";
    rev = "147f5673d0c1c3dcf66f78d677fd647e4a020219";
    hash = "sha256-dHQto08IwTDOIuFUp9jwm1MWkFi8v2YJ/UESrLuG71g=";
  };

  flashmla = stdenv.mkDerivation {
    pname = "flashmla";
    # https://github.com/vllm-project/FlashMLA/blob/${src.rev}/setup.py
    version = "1.0.0";

    # grep for GIT_TAG in the following file
    # https://github.com/vllm-project/vllm/blob/v${version}/cmake/external_projects/flashmla.cmake
    src = fetchFromGitHub {
      name = "FlashMLA-source";
      owner = "vllm-project";
      repo = "FlashMLA";
      rev = "a6ec2ba7bd0a7dff98b3f4d3e6b52b159c48d78b";
      hash = "sha256-Oj37H0swZdxaprpaHq0XfOCagc0ypYKpS8e6JzqcDQg=";
    };

    dontConfigure = true;

    # flashmla normally relies on `git submodule update` to fetch cutlass
    buildPhase = ''
      rm -rf csrc/cutlass
      ln -sf ${cutlass-flashmla} csrc/cutlass
    '';

    installPhase = ''
      cp -rva . $out
    '';
  };

  # grep for DEFAULT_TRITON_KERNELS_TAG in the following file
  # https://github.com/vllm-project/vllm/blob/v${version}/cmake/external_projects/triton_kernels.cmake
  triton-kernels = fetchFromGitHub {
    owner = "triton-lang";
    repo = "triton";
    tag = "v3.6.0";
    hash = "sha256-JFSpQn+WsNnh7CAPlcpOcUp0nyKXNbJEANdXqmkt4Tc=";
  };

  # grep for GIT_TAG in the following file
  # https://github.com/vllm-project/vllm/blob/v${version}/cmake/external_projects/qutlass.cmake
  qutlass = fetchFromGitHub {
    name = "qutlass-source";
    owner = "IST-DASLab";
    repo = "qutlass";
    rev = "830d2c4537c7396e14a02a46fbddd18b5d107c65";
    hash = "sha256-aG4qd0vlwP+8gudfvHwhtXCFmBOJKQQTvcwahpEqC84=";
  };

  # vLLM 0.20 added DeepGEMM as a sub-build, gated to sm_90a / sm_100 only.
  # On sm_120 (RTX 50-series consumer Blackwell) the cmake creates an empty
  # target — but FetchContent_Populate runs unconditionally before the gate,
  # so we still need to provide a source directory. Submodules (third-party/
  # {cutlass,fmt}) are only referenced inside the if(DEEPGEMM_ARCHS) block
  # and are unused on our path.
  # grep for GIT_TAG in cmake/external_projects/deepgemm.cmake
  deepgemm = fetchFromGitHub {
    name = "deepgemm-source";
    owner = "deepseek-ai";
    repo = "DeepGEMM";
    rev = "891d57b4db1071624b5c8fa0d1e51cb317fa709f";
    hash = "sha256-xbgkpMvh5NXuTk7nXkgPs9Pa91XQaTXRronHnSGPfHM=";
  };

  vllm-flash-attn' = lib.defaultTo
    (stdenv.mkDerivation {
      pname = "vllm-flash-attn";
      # https://github.com/vllm-project/flash-attention/blob/${src.rev}/vllm_flash_attn/__init__.py
      version = "2.7.2.post1";

      # grep for GIT_TAG in the following file
      # https://github.com/vllm-project/vllm/blob/v${version}/cmake/external_projects/vllm_flash_attn.cmake
      src = fetchFromGitHub {
        name = "flash-attention-source";
        owner = "vllm-project";
        repo = "flash-attention";
        rev = "f5bc33cfc02c744d24a2e9d50e6db656de40611c";
        hash = "sha256-Bdvg5ROX4EFccrRElYnbGtHS9FD9qLY9ZwYfqTUYOnA=";
      };

      # Hopper-build-failure fetchpatches (Dao-AILab/flash-attention PRs
      # #1719, #1723) carried in 0.19's package are dropped — sm_120-only
      # build doesn't compile Hopper paths, and the upstream rev moved past
      # those commits.

      dontConfigure = true;

      # vllm-flash-attn normally relies on `git submodule update` to fetch cutlass and composable_kernel
      buildPhase = ''
        rm -rf csrc/cutlass
        ln -sf ${cutlass} csrc/cutlass
      ''
      + lib.optionalString rocmSupport ''
        rm -rf csrc/composable_kernel;
        ln -sf ${rocmPackages.composable_kernel} csrc/composable_kernel
      '';

      installPhase = ''
        cp -rva . $out
      '';
    })
    vllm-flash-attn;

  cpuSupport = !cudaSupport && !rocmSupport;

  # https://github.com/pytorch/pytorch/blob/v2.9.1/torch/utils/cpp_extension.py#L2407-L2410
  supportedTorchCudaCapabilities =
    let
      real = [
        "3.5"
        "3.7"
        "5.0"
        "5.2"
        "5.3"
        "6.0"
        "6.1"
        "6.2"
        "7.0"
        "7.2"
        "7.5"
        "8.0"
        "8.6"
        "8.7"
        "8.9"
        "9.0"
        "9.0a"
        "10.0"
        "10.0a"
        "10.3"
        "10.3a"
        "11.0"
        "11.0a"
        "12.0"
        "12.0a"
        "12.1"
        "12.1a"
      ];
      ptx = lists.map (x: "${x}+PTX") real;
    in
    real ++ ptx;

  # NOTE: The lists.subtractLists function is perhaps a bit unintuitive. It subtracts the elements
  #   of the first list *from* the second list. That means:
  #   lists.subtractLists a b = b - a

  # For CUDA
  supportedCudaCapabilities = lists.intersectLists flags.cudaCapabilities supportedTorchCudaCapabilities;
  unsupportedCudaCapabilities = lists.subtractLists supportedCudaCapabilities flags.cudaCapabilities;

  isCudaJetson = cudaSupport && cudaPackages.flags.isJetsonBuild;

  # Use trivial.warnIf to print a warning if any unsupported GPU targets are specified.
  gpuArchWarner =
    supported: unsupported:
    trivial.throwIf (supported == [ ])
      (
        "No supported GPU targets specified. Requested GPU targets: "
        + strings.concatStringsSep ", " unsupported
      )
      supported;

  # Create the gpuTargetString.
  gpuTargetString = strings.concatStringsSep ";" (
    if gpuTargets != [ ] then
    # If gpuTargets is specified, it always takes priority.
      gpuTargets
    else if cudaSupport then
      gpuArchWarner supportedCudaCapabilities unsupportedCudaCapabilities
    else if rocmSupport then
      rocmPackages.clr.localGpuTargets or rocmPackages.clr.gpuTargets
    else
      throw "No GPU targets specified"
  );

  mergedCudaLibraries = with cudaPackages; [
    cuda_cudart # cuda_runtime.h, -lcudart
    cuda_cccl
    libcurand # curand_kernel.h
    libcusparse # cusparse.h
    libcusolver # cusolverDn.h
    cuda_nvtx
    cuda_nvrtc
    # cusparselt # cusparseLt.h
    libcublas
  ];

  # header path ends up missing rocthrust & its deps
  rocmExtraIncludeFlags = lib.concatMapStringsSep " " (pkg: "-I${lib.getInclude pkg}/include") [
    rocmPackages.rocthrust
    rocmPackages.rocprim
    rocmPackages.hipcub
  ];

  # Some packages are not available on all platforms
  nccl = shouldUsePkg (cudaPackages.nccl or null);

  getAllOutputs = p: [
    (lib.getBin p)
    (lib.getLib p)
    (lib.getDev p)
  ];

in

buildPythonPackage.override { stdenv = torch.stdenv; } (finalAttrs: {
  pname = "vllm";
  version = "0.20.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "vllm-project";
    repo = "vllm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NqcziIw7zVu8RmZx2HaZ9BEdLpRlNKVFxccDZZdTQfE=";
  };

  patches = [
    # Nix integration: surface cmakeFlags from the derivation into setup.py's
    # cmake_args, and propagate PYTHONPATH into model-registry subprocesses.
    ./0002-setup.py-nix-support-respect-cmakeFlags.patch
    ./0003-propagate-pythonpath.patch
    # Drop cuda.txt deps that aren't packaged in nixpkgs (tilelang,
    # fastsafetensors, nvidia-cutlass-dsl, quack-kernels). Each is either
    # lazily-imported with a graceful fallback or only used for code paths
    # we don't run on sm_120 (FA4 / DeepSeek V4). See patch header.
    ./0007-drop-cuda-reqs-without-nixpkgs.patch
    # Skip building FA3 (Hopper sm_90) entirely — vllm-flash-attn 2.7.2's
    # hopper/ kernels don't compile against CUTLASS 4.4.2, and we don't
    # need FA3 on sm_120. See patch header.
    ./0008-skip-fa3-for-non-hopper.patch
  ];

  postPatch = ''
    # Remove vendored pynvml entirely
    rm vllm/third_party/pynvml.py
    substituteInPlace tests/utils.py \
      --replace-fail \
        "from vllm.third_party.pynvml import" \
        "from pynvml import"
    substituteInPlace vllm/utils/import_utils.py \
      --replace-fail \
        "import vllm.third_party.pynvml as pynvml" \
        "import pynvml"

    # pythonRelaxDeps does not cover build-system
    substituteInPlace pyproject.toml \
      --replace-fail "torch ==" "torch >=" \
      --replace-fail "setuptools>=77.0.3,<81.0.0" "setuptools"

    # Ignore the python version check because it hard-codes minor versions and
    # lags behind `ray`'s python interpreter support
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'set(PYTHON_SUPPORTED_VERSIONS' \
        'set(PYTHON_SUPPORTED_VERSIONS "${lib.versions.majorMinor python.version}"'
  '';

  nativeBuildInputs = [
    which
  ]
  ++ lib.optionals rocmSupport [
    rocmPackages.hipcc
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
    autoAddDriverRunpath
  ]
  ++ lib.optionals isCudaJetson [
    cudaPackages.autoAddCudaCompatRunpath
  ];

  build-system = [
    cmake
    grpcio-tools
    jinja2
    ninja
    packaging
    setuptools
    setuptools-scm
    torch
  ];

  buildInputs =
    lib.optionals cpuSupport [
      onednn
    ]
    ++ lib.optionals (cpuSupport && stdenv.hostPlatform.isLinux) [
      numactl
    ]
    ++ lib.optionals cudaSupport (
      mergedCudaLibraries
      ++ (with cudaPackages; [
        nccl
        cudnn
        libcufile
      ])
    )
    ++ lib.optionals rocmSupport (
      with rocmPackages;
      [
        clr
        rocthrust
        rocprim
        hipsparse
        hipblas
        rocrand
        hiprand
        rocblas
        miopen-hip
        hipfft
        hipcub
        hipsolver
        rocsolver
        hipblaslt
        rocm-runtime
      ]
    )
    ++ lib.optionals stdenv.cc.isClang [
      llvmPackages.openmp
    ];

  dependencies = [
    aioprometheus
    amd-quark
    anthropic
    bitsandbytes
    blake3
    cachetools
    cbor2
    compressed-tensors
    depyf
    einops
    fastapi
    gguf
    grpcio
    grpcio-reflection
    ijson
    importlib-metadata
    kaldi-native-fbank
    llguidance
    lm-format-enforcer
    mcp
    mistral-common
    model-hosting-container-standards
    msgspec
    numba
    numpy
    openai
    openai-harmony
    opencv-python-headless
    opentelemetry-api
    opentelemetry-exporter-otlp
    opentelemetry-sdk
    opentelemetry-semantic-conventions-ai
    outlines
    pandas
    partial-json-parser
    prometheus-fastapi-instrumentator
    py-cpuinfo
    pyarrow
    pybase64
    pydantic
    python-json-logger
    python-multipart
    pyzmq
    ray
    sentencepiece
    setproctitle
    tiktoken
    tokenizers
    torch
    # vLLM needs Torch's compiler to be present in order to use torch.compile
    torch.stdenv.cc
    torchaudio
    torchvision
    transformers
    uvicorn
    xformers
    xgrammar
  ]
  ++ uvicorn.optional-dependencies.standard
  ++ aioprometheus.optional-dependencies.starlette
  ++ lib.optionals stdenv.targetPlatform.isLinux [
    psutil
    py-libnuma
  ]
  ++ lib.optionals cudaSupport [
    apache-tvm-ffi
    cupy
    flashinfer
    nvidia-ml-py
  ]
  ++ lib.optionals rocmSupport [
    amd-aiter
    rocmPackages.rocminfo
    amdsmi
    datasets
    peft
    timm
  ];

  optional-dependencies = {
    audio = [
      librosa
      soundfile
      mistral-common
    ]
    ++ mistral-common.optional-dependencies.audio;
  };

  dontUseCmakeConfigure = true;
  cmakeFlags = [
  ]
  ++ lib.optionals cudaSupport [
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_CUTLASS" "${lib.getDev cutlass}")
    (lib.cmakeFeature "FLASH_MLA_SRC_DIR" "${lib.getDev flashmla}")
    (lib.cmakeFeature "VLLM_FLASH_ATTN_SRC_DIR" "${lib.getDev vllm-flash-attn'}")
    (lib.cmakeFeature "QUTLASS_SRC_DIR" "${lib.getDev qutlass}")
    (lib.cmakeFeature "DEEPGEMM_SRC_DIR" "${lib.getDev deepgemm}")
    (lib.cmakeFeature "TORCH_CUDA_ARCH_LIST" "${gpuTargetString}")
    (lib.cmakeFeature "CUTLASS_NVCC_ARCHS_ENABLED" "${cudaPackages.flags.cmakeCudaArchitecturesString}")
    (lib.cmakeFeature "CUDA_TOOLKIT_ROOT_DIR" "${symlinkJoin {
      name = "cuda-merged-${cudaPackages.cudaMajorMinorVersion}";
      paths = builtins.concatMap getAllOutputs mergedCudaLibraries;
    }}")
    (lib.cmakeFeature "CAFFE2_USE_CUDNN" "ON")
    (lib.cmakeFeature "CAFFE2_USE_CUFILE" "ON")
    (lib.cmakeFeature "CUTLASS_ENABLE_CUBLAS" "ON")
  ];

  env =
    lib.optionalAttrs cudaSupport
      {
        VLLM_TARGET_DEVICE = "cuda";
        CUDA_HOME = "${lib.getDev cudaPackages.cuda_nvcc}";
        TRITON_KERNELS_SRC_DIR = "${lib.getDev triton-kernels}/python/triton_kernels/triton_kernels";
      }
    // lib.optionalAttrs rocmSupport {
      VLLM_TARGET_DEVICE = "rocm";
      PYTORCH_ROCM_ARCH = gpuTargetString;
      # vLLM's CMake logic checks `ROCM_PATH` to decide whether HIP/ROCm is available.
      ROCM_PATH = "${rocmPackages.clr}";
      TRITON_KERNELS_SRC_DIR = "${lib.getDev triton-kernels}/python/triton_kernels/triton_kernels";
      HIPFLAGS = rocmExtraIncludeFlags;
      CXXFLAGS = rocmExtraIncludeFlags;
    }
    // lib.optionalAttrs cpuSupport {
      VLLM_TARGET_DEVICE = "cpu";
      FETCHCONTENT_SOURCE_DIR_ONEDNN = "${onednn.src}";
    };

  preConfigure = ''
    # See: https://github.com/vllm-project/vllm/blob/v0.7.1/setup.py#L75-L109
    # There's also NVCC_THREADS but Nix/Nixpkgs doesn't really have this concept.
    export MAX_JOBS="$NIX_BUILD_CORES"
  '';

  pythonRelaxDeps = true;

  # These optional deps don't have nixpkgs packages yet. flashinfer-cubin
  # is a pre-built CUDA binary variant (we use flashinfer from source).
  # nvidia-cudnn-frontend is a header-only C++ lib used at build time.
  pythonRemoveDeps = [
    "flashinfer-cubin"
    "nvidia-cudnn-frontend"
  ];

  pythonImportsCheck = [ "vllm" ];
  makeWrapperArgs =
    lib.optionals cudaSupport [
      "--set"
      "VLLM_NCCL_SO_PATH"
      "${cudaPackages.nccl}/lib/libnccl.so"
    ]
    ++ lib.optionals rocmSupport [
      "--set"
      "CPLUS_INCLUDE_PATH"
      (lib.concatStringsSep ":" (
        map (p: "${lib.getInclude p}/include") (
          (with rocmPackages; [
            rocthrust
            rocprim
            clr
            hipsparse
            hipblas
            hipblas-common
            hipblaslt
            hipsolver
            rocsparse
            rocblas
            rocsolver
            hipfft
          ])
          ++ [
            pybind11
          ]
        )
      ))

      "--set"
      "HIP_DEVICE_LIB_PATH"
      "${rocmPackages.rocm-device-libs}/amdgcn/bitcode"

      "--prefix"
      "PATH"
      ":"
      "${rocmPackages.clr}/bin"
    ];

  passthru = {
    # make internal dependency available to overlays
    vllm-flash-attn = vllm-flash-attn';
    # updates the cutlass fetcher instead
    skipBulkUpdate = true;
  };

  meta = {
    description = "High-throughput and memory-efficient inference and serving engine for LLMs";
    changelog = "https://github.com/vllm-project/vllm/releases/tag/${finalAttrs.src.tag}";
    homepage = "https://github.com/vllm-project/vllm";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      happysalada
      lach
      daniel-fahey
      LunNova # esp. for ROCm
    ];
    badPlatforms = [
      # CMake Error at cmake/cpu_extension.cmake:188 (message):
      #   vLLM CPU backend requires AVX512, AVX2, Power9+ ISA, S390X ISA, ARMv8 or
      #   RISC-V support.
      "aarch64-darwin"

      # CMake Error at cmake/cpu_extension.cmake:78 (find_isa):
      # find_isa Function invoked with incorrect arguments for function named:
      # find_isa
      "x86_64-darwin"
    ];
  };
})
