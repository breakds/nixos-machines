# vLLM Important Details

This module is unusual for a "Python webserver" service: it uses a merged CUDA
toolkit symlinkJoin, an `/etc`-shipped `sitecustomize.py` with a triton
monkey-patch, `path = [ bash gcc-wrapper ninja cuda_nvcc ]`, a stripped-down
systemd sandbox, and `ExecPaths=/var/lib/vllm`.

Each of those is here because vLLM 0.20 + flashinfer + triton + torch.compile
all run a C++/CUDA JIT compiler at process startup to materialize kernels that
are not AOT-compiled for the host arch, `sm_120` in our case. On NixOS they
collectively assume a traditional `/usr/local/cuda` + `/bin/sh` shape that
nixpkgs does not ship by default.

Layers that surfaced during the lorian bring-up:

1. Inspector subprocess env wipe: vLLM's `_run_in_subprocess` in `registry.py`
   replaces env entirely with `{ PYTHONPATH: ... }`, dropping `HOME`,
   `CUDA_HOME`, `TRITON_CACHE_DIR`, and `XDG_CACHE_HOME` on the way into the
   child. Fixed by the 0003 patch in `pkgs/vllm/`, which merges `os.environ`
   instead of replacing it.

2. Triton write-fail on `/.triton`: `DynamicUser` leaves `HOME` empty, so
   triton's cache code constructs `~/.triton/cache` and tries to mkdir
   `/.triton`. Anchored `HOME`, `TRITON_CACHE_DIR`, and `XDG_CACHE_HOME` under
   `%S/vllm` so the cache lands in the writable state dir.

3. `dlopen` of triton's compiled `.so` fails with `mmap(PROT_EXEC)` `EACCES`:
   `UMask=0077` made Python's `open()` create the file mode `0o600`, without
   the owner exec bit. Triton itself has no chmod step. Patched at runtime via
   a tiny `sitecustomize.py` monkey-patch on `FileCacheManager.put`.

4. `DynamicUser+StateDirectory` bind-mounts `%S/vllm` with `noexec` by default.
   Even with the file mode fixed, the mount-level `noexec` still rejects
   `PROT_EXEC`. Exempted via `ExecPaths=/var/lib/vllm`.

5. gloo's interface enumeration opens `AF_NETLINK`. The default
   `RestrictAddressFamilies` list did not include it. This is moot after we
   stripped the broad systemd hardening, but it is worth noting because it is
   not obvious from the error string.

6. flashinfer JIT (`sm_120` NVFP4 GEMM, FP8-KV attention) requires a full C/C++
   toolchain on `PATH`: `which`, `nvcc`, `gcc-wrapper`, `ninja`, and crucially
   `bash`. Ninja does `posix_spawnp("sh")`, not `/bin/sh`; without `sh` on
   `PATH` it fails with the generic message `posix_spawn: No such file or
   directory`.

7. flashinfer's generated `build.ninja` uses `-isystem $CUDA_HOME/include` and
   `-L$CUDA_HOME/lib64`, assuming the traditional unified-tree layout.
   `cuda_nvcc` alone does not have `cuda_runtime.h` or `libcudart`. Solved by
   pointing `CUDA_HOME` at a symlinkJoin of `cudatoolkit` + `cudnn.{lib,include}`
   with a `lib64 -> lib` symlink on top.

8. dgx-spark's vLLM module avoided all of the above by running with
   `enforceEager=true` + int4 quantization, which routes around the JIT paths
   entirely. We cannot do that here because NVFP4 + CUDA graphs are the point.

If a future contributor is tempted to "simplify" this module by matching the
nixpkgs-ollama hardening pattern, be ready to re-derive all the above one error
message at a time.
