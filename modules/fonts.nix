{
  config,
  pkgs,
  ...
}: {
  # ── Nerd Fonts ──
  fonts.packages = with pkgs.nerd-fonts; [
    droid-sans-mono
    fira-code
    hack
    inconsolata
    jetbrains-mono
    meslo-lg
    noto
    symbols-only
  ];
}
