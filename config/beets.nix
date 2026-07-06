{ config, ... }:

{
  # ── beets (music library manager) ──────────────────────────────────
  # Organizes/tags the library that MPD plays (see config/mpd.nix).
  # The HM module installs pkgs.beets and writes `settings` to
  # ~/.config/beets/config.yaml. The library database itself
  # (~/.config/beets/library.db) is runtime state, not managed here.
  #
  # nixpkgs beets ships all builtin plugins enabled (chroma comes with
  # chromaprint's fpcalc wrapped in), so the `plugins` list below only
  # selects which ones are active — no package override needed.
  programs.beets = {
    enable = true;

    settings = {
      # Same tree MPD serves (services.mpd.musicDirectory).
      directory = "${config.home.homeDirectory}/Music";

      plugins = [
        "musicbrainz"   # metadata source — in beets 2.x this is a
                        # plugin, and an explicit `plugins` list like
                        # this one drops it unless named (without it,
                        # beets has NO candidate source and every
                        # import is skipped)
        "chroma"        # AcoustID fingerprinting — identifies untagged
                        # files by audio content
        "fromfilename"  # fallback guess from filename when fingerprint
                        # and tags both come up empty
        "fetchart"      # album art on import
        "embedart"      # embed fetched art into the files
        "duplicates"    # query tool for finding dupes post-import
      ];
      # mpdupdate is appended to this list by mpdIntegration below.

      import = {
        # Move (not copy) out of the staging directory: the staging
        # copy (~/Music-staging, taken from the Crucial500 takeout) is
        # disposable, and draining it doubles as a progress indicator.
        # The Crucial500 originals stay untouched until final wipe.
        move = true;
        # Write the corrected tags into the files themselves — the
        # point of the whole exercise.
        write = true;
        log = "${config.xdg.stateHome}/beets-import.log";
      };

      # Fingerprint every import candidate, not just on demand.
      chroma.auto = true;

      # Beets' default layout, declared for visibility:
      #   Artist/Album/01 Track.mp3, singletons under Non-Album/.
      paths = {
        default = "$albumartist/$album%aunique{}/$track $title";
        singleton = "Non-Album/$artist/$title";
        comp = "Compilations/$album%aunique{}/$track $title";
      };
    };

    # Enables the mpdupdate plugin, pointed at services.mpd's port:
    # MPD rescans its database automatically after each beets import.
    mpdIntegration.enableUpdate = true;
  };
}
