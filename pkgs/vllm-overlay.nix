# Overlay providing vllm 0.19.0 and the Python-package bumps it requires.
#
# Applied to nixpkgs-unstable (the CUDA-aware ML tree this repo already uses
# for ollama, stt-server, etc.). Staying on the host's current cudaPackages
# (12.9 on unstable as of writing) rather than switching to 13.x — sub-builds
# (cutlass 4.2.1, qutlass, vllm-flash-attn 2.7.2) all document CUDA 12.8+ as
# their floor, and we target sm_120 (RTX 50-series).
#
# Derived from graham33/nixos-dgx-spark's overlays/fixes.nix, trimmed to the
# subset needed on x86_64 without the CUDA-13.2 switch.
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      # New Python deps vllm 0.19 needs that aren't in nixpkgs yet.
      kaldi-native-fbank =
        python-final.callPackage ./kaldi-native-fbank { };
      opentelemetry-semantic-conventions-ai =
        python-final.callPackage ./opentelemetry-semantic-conventions-ai { };

      # vllm 0.19 imports ReasoningEffort, added after mistral-common 1.8.8.
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

      # vllm 0.19 requires opentelemetry-api >= 1.40.
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

      # Sibling bump so contrib stays in sync with api 1.40.
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

      # vllm itself: target Blackwell consumer (RTX 5090 = sm_120) only.
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
