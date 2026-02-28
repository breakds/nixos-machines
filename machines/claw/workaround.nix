# Workarounds for the Framework 13 AMD AI 300 Series (claw)
#
# Each workaround should clearly document why it is required, the root
# cause of the problem, and relevant links/issues so that we can
# revisit and remove them when upstream fixes land.

{ ... }:

{
  # Workaround: Disable CWSR (Compute Wave Save/Restore)
  #
  # Root cause: The amdgpu driver in kernel 6.18.x has a broken CWSR
  # code path for gfx1150 (Strix Point / Radeon 890M). This causes
  # MES (Micro Engine Scheduler) ring buffer saturation, leading to a
  # gfxhub page fault at address 0x0 from CPC, followed by cascading
  # "MES failed to respond to msg=MISC (WAIT_REG_MEM)" errors and a
  # complete system freeze requiring a hard power cycle. The GPU
  # reset/recovery path for gfx1150 is incomplete in the driver, so
  # the system cannot recover once the fault occurs.
  #
  # Disabling CWSR prevents the faulty code path from triggering.
  # CWSR is only used for GPU compute task preemption (OpenCL/ROCm),
  # so this has no impact on graphics, display, or video playback.
  #
  # Relevant links:
  #   - https://community.frame.work/t/attn-critical-bugs-in-amdgpu-driver-included-with-kernel-6-18-x-6-19-x/79221
  #   - https://community.frame.work/t/amd-gpu-mes-timeouts-causing-system-hangs-on-framework-laptop-13-amd-ai-300-series/71364
  #   - http://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg134406.html
  #   - https://bbs.archlinux.org/viewtopic.php?id=311085
  #   - https://github.com/ROCm/ROCm/issues/5590
  #
  # TODO: Remove this once the upstream fix (updated MES firmware +
  # lr_compute_wa kernel patch) is confirmed working in a newer kernel.
  boot.kernelParams = [ "amdgpu.cwsr_enable=0" ];
}
