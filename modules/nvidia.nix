{
  config,
  pkgs,
  ...
}: {
  # ── Kernel module configuration ────────────────────────────────────

  # The display is driven by the CPU's integrated AMD GPU (Ryzen 7
  # 9800X3D "Granite Ridge"), so the two Nvidia cards stay pure compute
  # for the LLM and never share a card between the compositor and CUDA
  # (which is what triggered the RC-watchdog Xid 8 freezes).

  # Nvidia-specific kernel parameters:
  # - modeset/fbdev: enable kernel modesetting and framebuffer device,
  #   required for Wayland compositors and early boot display.
  # - PreserveVideoMemoryAllocations: keep VRAM contents across
  #   suspend/resume so the desktop doesn't corrupt on wake.
  # - TemporaryFilePath: where to store VRAM contents during suspend.
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    # Silent boot — let Plymouth handle the visuals.
    "quiet"
    "splash"
    "udev.log_level=3"
  ];

  # Load GPU modules early in the boot process (initrd) so the display
  # works before the full system comes up. amdgpu drives the iGPU that
  # the greeter and niri run on.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "amdgpu"
  ];

  # ── Nvidia driver ──────────────────────────────────────────────────

  # Nvidia for compute/offload, amdgpu for the integrated display GPU.
  services.xserver.videoDrivers = ["nvidia" "amdgpu"];

  # amdgpu (the iGPU) needs redistributable firmware (gc/sdma/psp/vcn
  # blobs from linux-firmware) to initialize. This also turns on AMD CPU
  # microcode updates — hardware.cpu.amd.updateMicrocode keys off it.
  hardware.enableRedistributableFirmware = true;

  hardware.nvidia = {
    # Use the open-source kernel modules (required for RTX 5080).
    open = true;
    # Kernel modesetting — needed for Wayland and GDM.
    modesetting.enable = true;
    # Install nvidia-settings GUI for tweaking GPU options.
    nvidiaSettings = true;

    # Enable power management so the GPU suspends/resumes cleanly.
    # Fine-grained power management (runtime D3) is off because it
    # only applies to hybrid laptop GPUs (Optimus), not desktops.
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Pin the production driver branch (565 series) for stability.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # Cap the 3090's power limit to 270 W (default 350 W). Measured
  # A/B/A with llama.cpp: 37.3 tok/s at 270 W vs 29.9 at 350 W —
  # inference is memory-bandwidth-bound, and the lower cap keeps
  # GDDR6X cooler and boost clocks stable. Quieter, cooler, faster.
  systemd.services.nvidia-power-limit = {
    description = "Set RTX 3090 power limit";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -i 1 -pl 270";
    };
  };

  # Ensure /var/tmp exists for Nvidia's VRAM suspend storage.
  systemd.tmpfiles.rules = [
    "d /var/tmp 1777 root root -"
  ];

  # ── PRIME render offload ───────────────────────────────────────────
  # The desktop renders on the AMD iGPU (radeonsi/mesa defaults); this
  # wrapper pushes a program onto the Nvidia card (GPU 0, the 5080).
  # The Nvidia-specific env vars are scoped here instead of set globally,
  # so they can't force the compositor or browser onto Nvidia. Launch
  # games with `prime-run %command%` (Steam launch options) or
  # `prime-run <cmd>`.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "prime-run" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  # ── Graphics / OpenGL ──────────────────────────────────────────────
  # Enable hardware-accelerated graphics and add VA-API/VDPAU bridges
  # so video players can offload decoding to the GPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver # VDPAU backend for VA-API
      libvdpau-va-gl # VA-API backend for VDPAU (OpenGL fallback)
    ];
  };

  # No system-wide CUDA: GPU compute via Python wheels (torch etc.)
  # bundles its own CUDA runtime and needs only the driver above.
  # For compiling CUDA code, use a project dev shell with
  # cudaPackages.cudatoolkit instead of polluting the system closure.
}
