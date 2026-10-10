# Package-level fixes for broken nixpkgs builds. Each entry should carry a
# date + reason; remove once upstream is fixed.
{...}: {
  nixpkgs.overlays = [
    # 2026-10-10: ltrace's DejaGnu suite fails in the nix build sandbox
    # (ptrace-based tracing tests can't run), blocking every system build.
    (final: prev: {
      ltrace = prev.ltrace.overrideAttrs (old: {doCheck = false;});
    })
  ];
}