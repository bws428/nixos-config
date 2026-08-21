{pkgs, ...}: {
  # ── btop — interactive resource monitor ────────────────────────────
  # Uses Noctalia's wallpaper-driven theme, written by its btop template
  # to ~/.config/btop/themes/noctalia.theme. Declaring it here (rather
  # than letting Noctalia sed it in) keeps btop.conf an intact HM
  # symlink: Noctalia's post-hook no-ops when color_theme is already
  # "noctalia". On a fresh install btop uses default colors until the
  # first wallpaper apply.
  programs.btop = {
    enable = true;
    # Default btop is built without GPU_SUPPORT; the cuda variant links
    # NVML so the gpu0 box ("5" key) works.
    package = pkgs.btop-cuda;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
      # Show the GPU as its own box, not merged into the CPU box.
      shown_boxes = "cpu mem net gpu0 gpu1";
      show_gpu_info = "Off";
    };
  };
}
