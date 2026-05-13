# Header-only tensor-sharing lib pulled in transitively by torch/cupy
# under CUDA 13. Not in nixpkgs.

{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dlpack";
  version = "1.2";
  src = fetchFromGitHub {
    owner = "dmlc";
    repo = "dlpack";
    rev = "v${finalAttrs.version}";
    hash = "sha256-9sKjRGnoaHLUXjDahyWrYYYdDQuqwJyL0hFo1YhGov4=";
  };
  nativeBuildInputs = [ cmake ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/include
    cp -r $src/include/dlpack $out/include/
  '';
  meta = with lib; {
    description = "Open in-memory tensor structure for sharing tensors among frameworks";
    homepage = "https://github.com/dmlc/dlpack";
    license = licenses.asl20;
    platforms = platforms.all;
  };
})
