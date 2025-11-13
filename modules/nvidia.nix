{ config, pkgs, ... }:

{
  # Blacklist AMD GPU driver
  boot.blacklistedKernelModules = [ "amdgpu" ];

  # Nvidia-specific kernel parameters
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    # RTX 5080-specific parameters for suspend/resume
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];

  # Load Nvidia modules in initrd
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Enable Nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Nvidia driver configuration
  hardware.nvidia = {
    open = true;  # Required for RTX 5080
    modesetting.enable = true;
    nvidiaSettings = true;

    # Power management settings
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Use production driver (565 series)
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # Create temp directory for Nvidia driver
  systemd.tmpfiles.rules = [
    "d /var/tmp 1777 root root -"
  ];

  # Add environment variables for Nvidia + Wayland
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

    # CUDA support
    # Make CUDA available system-wide
    environment.systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.cutensor
      cudaPackages.nccl
      # cudaPackages.tensorrt  # If you need TensorRT

      # Useful tools
      nvidia-docker  # If you want to use Docker with CUDA
      nvitop        # Alternative GPU monitoring tool
    ];

    # Set CUDA environment variables system-wide
    environment.variables = {
      CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
      CUDA_ROOT = "${pkgs.cudaPackages.cudatoolkit}";
      EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";
      EXTRA_CCFLAGS = "-I/usr/include";
    };
}
