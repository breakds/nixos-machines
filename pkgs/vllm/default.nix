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
, rustPlatform
, setuptools
, setuptools-rust
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
, flashinfer-python
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
      rev = "a8f794d1251cbfd88a5011445dd5582289c727e4";
      hash = "sha256-k/Mbc70U8wbP4BHnxZ/I607Dc2EnIkhWYd9iKUG740Y=";
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
    tag = "v3.5.1";
    hash = "sha256-dyNRtS1qtU8C/iAf0Udt/1VgtKGSvng1+r2BtvT9RB4=";
  };

  # grep for GIT_TAG in the following file
  # https://github.com/vllm-project/vllm/blob/v${version}/cmake/external_projects/qutlass.cmake
  qutlass = fetchFromGitHub {
    name = "qutlass-source";
    owner = "IST-DASLab";
    repo = "qutlass";
    rev = "e74319e3405ce6d71965732880f5dc1f52371f64";
    hash = "sha256-Gzl3KuYXXLXMrVciEYrBPu1FH2cplGUPTFpWzFfUmMo=";
  };

  # DeepGEMM was gated to sm_90a / sm_100 when vLLM 0.20 added it, so on
  # sm_120 the cmake used to fall through to an empty target and only needed a
  # source directory to satisfy FetchContent_Populate. 0.28.0 added "12.0f" to
  # DEEPGEMM_SUPPORT_ARCHS, so it now genuinely compiles for us — and its
  # kernels include cute/ headers out of third-party/cutlass, which upstream
  # pulls via GIT_SUBMODULES. Fetch the submodules or the build dies on a
  # missing cute/arch/mma_sm100_desc.hpp.
  # grep for GIT_TAG in cmake/external_projects/deepgemm.cmake
  deepgemm = fetchFromGitHub {
    name = "deepgemm-source";
    owner = "deepseek-ai";
    repo = "DeepGEMM";
    rev = "8b1392b978f5a03c828dd1711090d7fb50958b8a";
    fetchSubmodules = true;
    hash = "sha256-Dy3s3LJXkvgKAOMOwyissYjr47OjkwqlShVKUthL/II=";
  };

  # The three sub-builds below are new in vLLM 0.24-0.28. Each one's cmake
  # runs FetchContent_Populate unconditionally for CUDA, so all three need a
  # source directory even when the kernels themselves are gated off — leaving
  # any of them unset makes the build try to git-clone inside the sandbox.
  # grep for GIT_TAG in cmake/external_projects/{tml_fa4,flashkda,fmha_sm100}.cmake

  # FA4 CuteDSL kernels. No submodules.
  tml-fa4 = fetchFromGitHub {
    name = "tml-fa4-source";
    owner = "vllm-project";
    repo = "tml-fa4";
    rev = "b206834606ed5b5f21f8eed6b0683f528ea9cf7d";
    hash = "sha256-LDA5bW4Bf5+w41K9aJ5flz372hy+Ukm//RT55L7nbbU=";
  };

  # Kimi Delta Attention. Unlike deepgemm this one does compile for us:
  # flashkda.cmake lists "12.0f" as supported from CUDA 13.0, and its sources
  # include ${flashkda_SOURCE_DIR}/cutlass/{include,examples,tools} — so the
  # bundled cutlass submodule has to be present, not just the top-level repo.
  flashkda = fetchFromGitHub {
    name = "flashkda-source";
    owner = "vllm-project";
    repo = "FlashKDA";
    rev = "053de1b716ef3255873e02d2d28f4adf09951978";
    fetchSubmodules = true;
    hash = "sha256-ew0xOyDP3Z+2c0azRf+nESZ4wgRXe/qQIyl7K+MmgKI=";
  };

  # Multi-head Sparse Attention, sm_100 only — nothing compiles on sm_120, but
  # fmha_sm100.cmake still install()s Python and headers out of its cutlass
  # submodule, so fetch that too.
  fmha-sm100 = fetchFromGitHub {
    name = "fmha-sm100-source";
    owner = "vllm-project";
    repo = "MSA";
    rev = "087c161814d4d9c735b46c21212a09e5f8eb92fa";
    fetchSubmodules = true;
    hash = "sha256-y1NZBwmpiILIDb4ph1NJ+0jU1Tg4qP3y4w3tOCN4gEw=";
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
        rev = "f3e1a4f74c99145c0717709860bf765de1703779";
        hash = "sha256-/szsVNSp1LvT2Ojbj67jy6tY31RTPR1qW2XzcB31B80=";
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

  # https://github.com/pytorch/pytorch/blob/v2.11.0/torch/utils/cpp_extension.py#L2407-L2410
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
    cccl
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
  version = "0.28.0";
  pyproject = true;
  cargoRoot = "rust";

  src = fetchFromGitHub {
    owner = "vllm-project";
    repo = "vllm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ia5SB9bQ+Vxkc5wBwY7HxQo6rqYFpWlVxeQyyP55dMg=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src cargoRoot;
    hash = "sha256-CLvLAkejYfrnrPXJ78xh2mgCyRg7F56Um1LPnJtj7iw=";
  };

  patches = [
    # Nix integration: propagate PYTHONPATH into model-registry subprocesses.
    ./0003-propagate-pythonpath.patch
    # Skip building FA3 (Hopper sm_90) entirely — vllm-flash-attn's
    # hopper/ kernels have been fragile against CUTLASS 4.x, and we don't
    # need FA3 on sm_120. See patch header.
    ./0008-skip-fa3-for-non-hopper.patch
    # Avoid importing humming-kernels while probing unrelated quantization
    # methods; the dependency is optional and not packaged here.
    ./0009-guard-optional-humming-quantization.patch
    # Keep vllm.parser.harmony importable against xgrammar 0.1.33, which has
    # no openai_tool_call_schema. Four modules import harmony, so the guard
    # belongs in harmony itself. See patch header.
    ./0010-guard-harmony-parser-import.patch
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

    # pythonRelaxDeps does not cover build-system, so relax those pins here.
    #
    # Drop the torch constraint outright rather than loosening == to >=.
    # 0.28.0 asks for torch 2.13.0 and nixpkgs has 2.12.0 everywhere,
    # including master, so >= is still unsatisfiable — vLLM went 2.11 -> 2.13
    # and skipped the version we have. Pinning the exact string means the next
    # bump trips --replace-fail instead of silently keeping a stale rule.
    #
    # This only clears the metadata gate. Whether vLLM's CUDA sources actually
    # compile against 2.12's ATen/c10 headers is settled later, in the build.
    substituteInPlace pyproject.toml \
      --replace-fail '"torch == 2.13.0"' '"torch"' \
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
    rustPlatform.cargoSetupHook
    setuptools
    setuptools-rust
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
    flashinfer-python
    nvidia-ml-py
  ]
  ++ lib.optionals rocmSupport [
    amd-aiter
    amd-quark
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
    (lib.cmakeFeature "TML_FA4_SRC_DIR" "${lib.getDev tml-fa4}")
    (lib.cmakeFeature "FLASH_KDA_SRC_DIR" "${lib.getDev flashkda}")
    (lib.cmakeFeature "FMHA_SM100_SRC_DIR" "${lib.getDev fmha-sm100}")
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
        CMAKE_ARGS = lib.concatStringsSep " " finalAttrs.cmakeFlags;
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

  # Optional deps with no nixpkgs package. This list used to be split between
  # here and a patch against requirements/cuda.txt, but that patch's context
  # moved on every vLLM bump; stripping the metadata instead does the same job
  # and survives version changes. vLLM either imports each of these lazily
  # with a fallback, or never reaches them on the sm_120 NVFP4 path:
  #
  #   flashinfer-cubin      pre-built CUDA binaries (we build flashinfer from source)
  #   nvidia-cudnn-frontend header-only C++ lib, build-time only
  #   tilelang              DeepSeek V4 / MHC paths, probed via has_tilelang()
  #   fastsafetensors       weight_utils.py wraps the import in try/except
  #   nvidia-cutlass-dsl    CuteDSL kernels; we use the vendored CUTLASS/QuTLASS
  #   quack-kernels         ditto (required by MSA for CUTLASS DSL 4.6)
  #   tokenspeed-mla        faster MLA with spec decode; not on Qwen3's GDN path
  #   humming-kernels       optional mixed-precision quantization backend
  #   PyNvVideoCodec        hardware video decode; the image path doesn't need it
  #   nvtx                  only for LLM_NVTX_SCOPES_FOR_PROFILING=1
  pythonRemoveDeps = [
    "flashinfer-cubin"
    "nvidia-cudnn-frontend"
    "tilelang"
    "fastsafetensors"
    "nvidia-cutlass-dsl"
    "quack-kernels"
    "tokenspeed-mla"
    "humming-kernels"
    "PyNvVideoCodec"
    "nvtx"
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
