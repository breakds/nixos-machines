{ lib, fetchFromGitHub, cudaPackages, cmake, ninja, makeWrapper
, autoAddDriverRunpath, python3 }:

let
  python = python3.withPackages (ps: with ps; [
    numpy jinja2 markupsafe regex pyyaml tqdm pillow psutil
  ]);
  toolkit = cudaPackages.cudatoolkit;
in cudaPackages.backendStdenv.mkDerivation {
  pname = "basalt-inference";
  version = "0.3.2-unstable-2026-11-08";

  src = fetchFromGitHub {
    owner = "jesdga95";
    repo = "basalt";
    rev = "f19f69e68cdb5e6203a20b5c5563b1288fcb35a7";
    hash = "sha256-jmbTautmDwx25+bZiyj4561KBJ328/RktRScU/MQW+Q=";
  };

  nativeBuildInputs = [ cmake ninja makeWrapper autoAddDriverRunpath ];
  buildInputs = [ toolkit ];

  postPatch = ''
    # The benchmark tools otherwise retain paths into the temporary build tree.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'BASALT_BENCH_ENGINE="$<TARGET_FILE:basalt>"' "BASALT_BENCH_ENGINE=\"$out/bin/basalt\"" \
      --replace-fail 'BASALT_BENCH_DEVICE="$<TARGET_FILE:basalt-device>"' "BASALT_BENCH_DEVICE=\"$out/bin/basalt-device\"" \
      --replace-fail 'BASALT_BENCH_FIXTURES="''${CMAKE_CURRENT_SOURCE_DIR}/data/bench"' "BASALT_BENCH_FIXTURES=\"$out/data/bench\"" \
      --replace-fail 'BASALT_BENCH_SOURCE_DIR="''${CMAKE_CURRENT_SOURCE_DIR}"' "BASALT_BENCH_SOURCE_DIR=\"$out\""
    substituteInPlace cmake/git_stamp.cmake \
      --replace-fail 'set(_git unknown)' 'set(_git f19f69e68c)'
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_CUDA_ARCHITECTURES=120"
    "-DCMAKE_CUDA_COMPILER=${toolkit}/bin/nvcc"
    "-DCMAKE_CUDA_HOST_COMPILER=${cudaPackages.backendStdenv.cc}/bin/g++"
    "-DCUDAToolkit_ROOT=${toolkit}"
    # nvcc's Nix profile names its own headers, not the separate runtime headers.
    "-DCMAKE_CUDA_FLAGS=-I${toolkit}/include"
    "-DCMAKE_CXX_FLAGS=-I${toolkit}/include"
  ];
  ninjaFlags = [ "basalt" "basalt-bench" "basalt-probe" "basalt-vision" ];
  enableParallelBuilding = true;

  doCheck = true;
  nativeCheckInputs = [ python ];
  checkPhase = ''
    runHook preCheck
    (
      cd ..
      ${python}/bin/python -B -m unittest \
        serve.tests.test_config \
        serve.tests.test_deepseek41_dialect \
        serve.tests.test_server
    )
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp ../bin/basalt{,-bench,-probe,-vision} "$out/bin/"
    cp basalt-device "$out/bin/"
    # The engine resolves its server and profiles relative to the parent of bin/.
    cp -r ../serve ../tools ../data "$out/"
    install -Dm644 ../LICENSE "$out/share/licenses/basalt/LICENSE"
    install -Dm644 ../THIRD_PARTY_LICENSES "$out/share/licenses/basalt/THIRD_PARTY_LICENSES"
    wrapProgram "$out/bin/basalt" \
      --prefix PATH : ${lib.makeBinPath [ python toolkit ]} \
      --set PYTHONDONTWRITEBYTECODE 1
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/basalt" serve --help > /dev/null
    runHook postInstallCheck
  '';

  passthru = { inherit python; };
  meta = {
    description = "Local MoE inference engine for NVIDIA Blackwell";
    homepage = "https://github.com/jesdga95/basalt";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "basalt";
  };
}
