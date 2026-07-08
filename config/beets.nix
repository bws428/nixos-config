{
  config,
  pkgs,
  ...
}: {
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

    # Make the chroma plugin read its AcoustID client key from a local
    # file, falling back to the stock key. The key is a module constant
    # in beetsplug/chroma.py (no config option exists for it), and the
    # stock key is shared by every beets install worldwide against a
    # global 10 req/s budget — fingerprint lookups randomly fail with
    # rate-limit errors that beets logs as "no match found". A personal
    # key (free, https://acoustid.org/new-application) fixes that, but
    # this repo is public, so the key itself lives OUTSIDE the repo:
    #
    #   echo -n '<key>' > ~/.config/beets/acoustid-client-key
    #
    # One-time imperative step on a fresh install; without the file,
    # chroma still works on the (unreliable) shared key.
    package = pkgs.python3Packages.toPythonApplication (
      pkgs.python3Packages.beets.overridePythonAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace beetsplug/chroma.py \
              --replace-fail 'API_KEY = "1vOwZtEn"' 'import pathlib; _KEYFILE = pathlib.Path.home() / ".config/beets/acoustid-client-key"; API_KEY = ((_KEYFILE.read_text().strip() if _KEYFILE.exists() else "") or "1vOwZtEn")'
          '';
      })
    );

    settings = {
      # Same tree MPD serves (services.mpd.musicDirectory).
      directory = "${config.home.homeDirectory}/Music";

      plugins = [
        "musicbrainz" # metadata source — in beets 2.x this is a
        # plugin, and an explicit `plugins` list like
        # this one drops it unless named (without it,
        # beets has NO candidate source and every
        # import is skipped)
        "chroma" # AcoustID fingerprinting — identifies untagged
        # files by audio content
        "fromfilename" # fallback guess from filename when fingerprint
        # and tags both come up empty
        "fetchart" # album art on import
        "embedart" # embed fetched art into the files
        "duplicates" # query tool for finding dupes post-import
      ];
      # mpdupdate is appended to this list by mpdIntegration below.

      import = {
        # Move (not copy) source files into the library on import, so
        # a `beet import ~/Downloads/album` leaves no stragglers
        # behind.
        move = true;
        # Write the corrected tags into the files themselves — the
        # point of the whole exercise.
        write = true;
        log = "${config.xdg.stateHome}/beets-import.log";
      };

      # Fingerprint every import candidate, not just on demand.
      chroma.auto = true;

      # Kill the "≠ data source" penalty on MusicBrainz candidates.
      # Whenever >1 metadata plugin is loaded (musicbrainz + chroma
      # here), beets docks EVERY candidate for a never-imported file by
      # this amount (default 0.5, weighted 2.0) — capping otherwise
      # correct matches at ~86-89%, below any auto-accept threshold
      # (benchmark: 0/40 auto-imports with the default, 28/40 zeroed).
      # The knob lives on the plugin that PROVIDES the candidates
      # (musicbrainz), not chroma.
      musicbrainz.data_source_mismatch_penalty = 0.0;

      # Auto-accept matches scoring >= 90% in quiet mode (default is a
      # brutal 96%: popular songs with many near-identical MusicBrainz
      # recordings get confidence-downgraded below it even when the
      # match is right). Tradeoff: slightly higher odds of a
      # wrong-release match (e.g. greatest-hits instead of the studio
      # album) — acceptable for this library, and fixable per-file
      # later with `beet import -L`.
      match.strong_rec_thresh = 0.10;

      # Library layout. This library is mostly loose tracks, so
      # singletons file directly under Artist/ rather than beets'
      # default Non-Album/Artist/ — a wrapper dir around ~90% of the
      # library would be pointless nesting. Real album matches and
      # compilations keep their trees.
      paths = {
        default = "$albumartist/$album%aunique{}/$track $title";
        singleton = "$artist/$title";
        comp = "Compilations/$album%aunique{}/$track $title";
      };
    };

    # Enables the mpdupdate plugin, pointed at services.mpd's port:
    # MPD rescans its database automatically after each beets import.
    mpdIntegration.enableUpdate = true;
  };
}
