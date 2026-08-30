{
  config,
  pkgs,
  ...
}: {
  # ── Kernel module configuration ────────────────────────────────────

  # The display is driven by the RTX 5080. The RTX 3090 stays pure LLM
  # compute, so the compositor never shares a card with CUDA (which is
  # what triggered the RC-watchdog Xid 8 freezes). The AMD iGPU stays
  # loaded as a fallback display only.

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
  # works before the full system comes up. nvidia drives the 5080 that
  # the greeter and niri run on; amdgpu stays for the iGPU fallback.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "amdgpu"
  ];

  # ── Nvidia driver ──────────────────────────────────────────────────

  # Nvidia (5080) drives the display; amdgpu stays loaded for the iGPU
  # fallback.
  services.xserver.videoDrivers = ["nvidia" "amdgpu"];

  # amdgpu (the iGPU) needs redistributable firmware (gc/sdma/psp/vcn
  # blobs from linux-firmware) to initialize. This also turns on AMD CPU
  # microcode updates — hardware.cpu.amd.updateMicrocode keys off it.
  hardware.enableRedistributableFirmware = true;

  # Colon-free aliases for the DRM card nodes. WLR_DRM_DEVICES is a
  # colon-separated list, so the by-path names (e.g. pci-0000:01:00.0-card)
  # get split on their colons and the greeter opens nothing. The greeter
  # points at /dev/dri/card-nvidia (the 5080); card-amdgpu stays as the
  # iGPU fallback alias.
  services.udev.extraRules = ''
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", KERNELS=="0000:7a:00.0", SYMLINK+="dri/card-amdgpu"
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", KERNELS=="0000:01:00.0", SYMLINK+="dri/card-nvidia"
  '';

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
