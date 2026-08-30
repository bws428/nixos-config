{pkgs, ...}: {
  # ── btop ──
  programs.btop = {
    enable = true;
    # cuda variant links NVML so the GPU box works.
    package = pkgs.btop-cuda;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
      # GPU as its own box.
      shown_boxes = "cpu mem gpu0 gpu1";
      show_gpu_info = "Off";
    };
  };
}
