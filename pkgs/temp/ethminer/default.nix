# Compared to the ethminer on nixpkgs master, this one uses a
# different commit from ethminer (master uses 0.19 release)
#
# I think the chosen commit fixed a bug so that it can correctly
# recognize CUDA 11 for ethash. Otherwise as a result it will not drop
# "compute_30" for CUDA 11 (but CUDA 11 does not have it), and result
# in compilation failure.

{
  lib,
  stdenv,
  fetchFromGitHub,
  opencl-headers,
  cmake,
  jsoncpp,
  boost16x,
  makeWrapper,
  cudatoolkit,
  cudaSupport,
  mesa,
  ethash,
  opencl-info,
  ocl-icd,
  openssl,
  pkg-config,
  cli11
}:

stdenv.mkDerivation rec {
  pname = "ethminer";
  version = "dev.20210209";

  src =
    fetchFromGitHub {
      owner = "breakds";
      repo = "ethminer";
      rev = "ce52c74021b6fbaaddea3c3c52f64f24e39ea3e9";
      sha256 = "sha256-yTFsN0M3gTF0YhUPP6sOT/DHfSALKyxbuYLEdXUpag0=";
      fetchSubmodules = true;
    };

  # NOTE: dbus is broken
  cmakeFlags = [
    "-DHUNTER_ENABLED=OFF"
    "-DETHASHCUDA=ON"
    "-DAPICORE=ON"
    "-DETHDBUS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ] ++ (if cudaSupport then [
    "-DCUDA_PROPAGATE_HOST_FLAGS=off"
  ] else [
    "-DETHASHCUDA=OFF" # on by default
  ]);

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    cli11
    boost16x # 1.7x support is broken, see https://github.com/ethereum-mining/ethminer/issues/2393
    opencl-headers
    mesa
    ethash
    opencl-info
    ocl-icd
    openssl
    jsoncpp
  ] ++ lib.optionals cudaSupport [
    cudatoolkit
  ];

  patches = [
    # global context library is separated from libethash
    ./add-global-context.patch
  ];

  preConfigure = ''
    sed -i 's/_lib_static//' libpoolprotocols/CMakeLists.txt
  '';

  postInstall = ''
    wrapProgram $out/bin/ethminer --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
  '';

  meta = with lib; {
    description = "Ethereum miner with OpenCL${lib.optionalString cudaSupport ", CUDA"} and stratum support";
    homepage = "https://github.com/ethereum-mining/ethminer";
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ atemu ];
    license = licenses.gpl3Only;
  };
}
