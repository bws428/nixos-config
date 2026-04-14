{ config, pkgs, ... }:

{
  # ── Nerd Fonts ─────────────────────────────────────────────────────
  # https://nixos.wiki/wiki/Fonts
  # https://mynixos.com/nixpkgs/packages/nerd-fonts
  #
  # Nerd Fonts patch popular programming fonts with thousands of icons
  # (Devicons, Font Awesome, Powerline, etc.) used by terminal tools,
  # status bars, and editors. The "symbols-only" package provides just
  # the icon glyphs as a fallback font so any application can render them.
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
