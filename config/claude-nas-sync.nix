{ config, pkgs, ... }:

let
  # ── The sync script ───────────────────────────────────────────────
  # Mirrors a curated subset of ~/.claude/ to a Synology NAS over rsync
  # over SSH. Bidirectional via newer-mtime-wins (--update). Designed
  # so that a NAS-unreachable run (offline, VPN down, etc.) exits 0
  # cleanly instead of breaking a Claude SessionStart hook.
  #
  # Subcommands:
  #   pull       NAS → local
  #   push       local → NAS
  #   sync       pull && push    (the timer uses this)
  #
  # Optional flag:
  #   --dry-run  pass-through to rsync (and skip ssh writes)
  #
  # Project mapping lives at ~/.claude/sync-projects.tsv (created in a
  # later step). Format: canonical<TAB>linux_encoded<TAB>mac_encoded.
  # If absent, the script syncs the common set only and logs a notice.
  syncScript = pkgs.writeShellApplication {
    name = "claude-nas-sync";

    # Override default; we deliberately want to continue past per-project
    # rsync failures rather than aborting the whole run.
    bashOptions = [ "nounset" "pipefail" ];

    runtimeInputs = with pkgs; [
      rsync
      openssh
      coreutils
      gawk
    ];

    text = ''
      NAS_HOST="claudesync-nas"
      NAS_BASE="/volume1/claudesync"
      LOCAL_CLAUDE="$HOME/.claude"
      MAPPING="$LOCAL_CLAUDE/sync-projects.tsv"
      LOG_DIR="$HOME/.local/state"
      LOG="$LOG_DIR/claude-nas-sync.log"

      # This script ships only to the NixOS box; column 2 of the TSV is
      # the linux_encoded project dir. The Mac will get its own variant
      # later that reads column 3.
      OUR_COL=2

      mkdir -p "$LOG_DIR"

      log() { printf "[%s] %s\n" "$(date -Is)" "$*" >> "$LOG"; }

      DRY=""
      RSYNC_DRY=""
      for arg in "$@"; do
        if [ "$arg" = "--dry-run" ]; then
          DRY="1"
          RSYNC_DRY="--dry-run"
        fi
      done

      reachable() {
        ssh -o BatchMode=yes -o ConnectTimeout=5 "$NAS_HOST" true 2>/dev/null
      }

      sync_common() {
        # direction: pull | push
        local direction="$1"
        local src dst
        if [ "$direction" = "pull" ]; then
          src="$NAS_HOST:$NAS_BASE/common/"
          dst="$LOCAL_CLAUDE/"
        else
          src="$LOCAL_CLAUDE/"
          dst="$NAS_HOST:$NAS_BASE/common/"
        fi

        # shellcheck disable=SC2086
        if rsync -az --update $RSYNC_DRY \
            --include='/CLAUDE.md' \
            --include='/settings.json' \
            --include='/statusline-command.sh' \
            --include='/mcp-needs-auth-cache.json' \
            --include='/docs/***' \
            --include='/plans/***' \
            --include='/plugins/***' \
            --exclude='*' \
            "$src" "$dst" 2>>"$LOG"; then
          log "$direction common: ok"
        else
          log "$direction common: rsync exited non-zero (continuing)"
        fi
      }

      sync_memory() {
        local direction="$1"
        if [ ! -f "$MAPPING" ]; then
          log "$direction memory: $MAPPING not found, skipping per-project mirror"
          return 0
        fi

        # Skip header, read tab-separated rows, dispatch per project.
        tail -n +2 "$MAPPING" | while IFS=$'\t' read -r canonical linux_enc mac_enc; do
          # Skip empty / comment rows
          case "$canonical" in
            ""|"#"*) continue ;;
          esac

          local our_enc
          if [ "$OUR_COL" = "2" ]; then
            our_enc="$linux_enc"
          else
            our_enc="$mac_enc"
          fi

          local local_dir="$LOCAL_CLAUDE/projects/$our_enc/memory"
          local nas_dir="$NAS_BASE/memory/$canonical"

          if [ "$direction" = "pull" ]; then
            mkdir -p "$local_dir"
            # shellcheck disable=SC2086
            if rsync -az --update $RSYNC_DRY \
                "$NAS_HOST:$nas_dir/" "$local_dir/" 2>>"$LOG"; then
              log "pull memory[$canonical]: ok"
            else
              log "pull memory[$canonical]: rsync exited non-zero"
            fi
          else
            # push: skip projects that don't exist locally
            if [ ! -d "$local_dir" ]; then
              continue
            fi
            if [ -z "$DRY" ]; then
              # shellcheck disable=SC2029
              ssh "$NAS_HOST" "mkdir -p '$nas_dir'" 2>>"$LOG" || true
            fi
            # shellcheck disable=SC2086
            if rsync -az --update $RSYNC_DRY \
                "$local_dir/" "$NAS_HOST:$nas_dir/" 2>>"$LOG"; then
              log "push memory[$canonical]: ok"
            else
              log "push memory[$canonical]: rsync exited non-zero"
            fi
          fi
        done
      }

      cmd="''${1:-}"
      # Strip leading --dry-run if it landed in $1 by itself
      if [ "$cmd" = "--dry-run" ]; then
        cmd="''${2:-}"
      fi

      case "$cmd" in
        pull|push)
          if ! reachable; then
            log "$cmd: NAS unreachable, exiting 0"
            exit 0
          fi
          log "$cmd: begin''${DRY:+ (dry-run)}"
          sync_common "$cmd"
          sync_memory "$cmd"
          log "$cmd: end"
          ;;

        sync)
          if ! reachable; then
            log "sync: NAS unreachable, exiting 0"
            exit 0
          fi
          log "sync: begin''${DRY:+ (dry-run)}"
          sync_common pull
          sync_memory pull
          sync_common push
          sync_memory push
          log "sync: end"
          ;;

        ""|-h|--help)
          cat <<USAGE
Usage: claude-nas-sync {pull|push|sync} [--dry-run]

  pull    fetch from NAS into ~/.claude/
  push    upload from ~/.claude/ to NAS
  sync    pull then push (used by the systemd timer)

NAS host alias: $NAS_HOST  (see ~/.ssh/config)
NAS base:       $NAS_BASE
Project map:    $MAPPING
Log file:       $LOG
USAGE
          ;;

        *)
          echo "claude-nas-sync: unknown command: $cmd" >&2
          echo "Try: claude-nas-sync --help" >&2
          exit 2
          ;;
      esac
    '';
  };

in {
  # Make the script available on PATH (and via an absolute path for the
  # systemd unit below).
  home.packages = [ syncScript ];

  # ── systemd user service ──────────────────────────────────────────
  # Oneshot wrapper around `claude-nas-sync sync`. The script handles
  # NAS-unreachable internally and always exits 0, so this unit will
  # not enter a failed state on offline boots.
  systemd.user.services.claude-nas-sync = {
    Unit = {
      Description = "Sync ~/.claude/ with the Synology NAS";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}/bin/claude-nas-sync sync";
    };
  };

  # ── systemd user timer ────────────────────────────────────────────
  # Declared but NOT auto-enabled (no Install.WantedBy). Enable manually
  # once the rest of the pipeline is wired up:
  #   systemctl --user enable --now claude-nas-sync.timer
  systemd.user.timers.claude-nas-sync = {
    Unit.Description = "Periodic Claude NAS sync";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Persistent = true;
      RandomizedDelaySec = "60s";
    };
  };
}
