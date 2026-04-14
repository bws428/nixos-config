{ config, pkgs, ... }:

{
  # ── Kernel module configuration ────────────────────────────────────

  # Prevent the AMD GPU driver from loading — this machine uses an
  # Nvidia GPU exclusively and the AMD driver can cause conflicts.
  boot.blacklistedKernelModules = [ "amdgpu" ];

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
  ];

  # Load Nvidia modules early in the boot process (initrd) so the
  # display works before the full system comes up.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # ── Nvidia driver ──────────────────────────────────────────────────

  # Tell the X/Wayland stack to use the Nvidia driver.
  services.xserver.videoDrivers = [ "nvidia" ];

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

  # Ensure /var/tmp exists for Nvidia's VRAM suspend storage.
  systemd.tmpfiles.rules = [
    "d /var/tmp 1777 root root -"
  ];

  # ── Wayland environment variables ──────────────────────────────────
  # These tell Wayland compositors and Mesa to use the Nvidia driver
  # for hardware video decode (VA-API), GBM buffer allocation, and
  # GLX rendering. WLR_NO_HARDWARE_CURSORS works around cursor
  # rendering issues on some Nvidia + wlroots compositor combos.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # ── Graphics / OpenGL ──────────────────────────────────────────────
  # Enable hardware-accelerated graphics and add VA-API/VDPAU bridges
  # so video players can offload decoding to the GPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver  # VDPAU backend for VA-API
      libvdpau-va-gl      # VA-API backend for VDPAU (OpenGL fallback)
    ];
  };

  # ── CUDA ───────────────────────────────────────────────────────────
  # Make CUDA libraries available system-wide for GPU-accelerated
  # workloads (machine learning, scientific computing, etc.).
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.nccl
  ];

  # Point build tools at the CUDA installation so compilers and
  # linkers can find headers and shared libraries.
  environment.variables = {
    CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudaPackages.cudatoolkit}";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
  };
}
