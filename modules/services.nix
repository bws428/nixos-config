{
  config,
  pkgs,
  lib,
  ...
}: {
  # ── Printing (CUPS) ────────────────────────────────────────────────
  # Declarative IPP Everywhere queue for the office Brother MFC-L3720CDW.
  # The printer advertises driverless IPP (URF / PWG-Raster), so no vendor
  # driver is needed and no PPD has to be carried — `model = "everywhere"`
  # tells lpadmin to fetch the printer's own IPP attributes.
  #
  # deviceUri uses the printer's IP, NOT its mDNS .local name. The
  # everywhere model is resolved by cupsd (lpadmin hands the URI to the
  # local scheduler, which connects to the printer to fetch attributes),
  # and cupsd cannot resolve `.local` in its own context — an
  # `ipp://…​.local/…` URI fails at queue-creation time with
  # "Unable to connect … System error" even though the printer is
  # reachable and shell tools (avahi/ipptool) resolve it fine. Using the
  # IP sidesteps that entirely. Tradeoff: the IP must stay put — set a
  # DHCP reservation for the printer's MAC on the router (e86538073798) so
  # a lease change can't silently break the queue. If printing ever stops,
  # confirm the current address with `avahi-resolve -n
  # BRWE86538073798.local` and update the IP below.
  #
  # cups-browsed is intentionally disabled: it auto-creates ephemeral
  # `implicitclass://` queues from mDNS adverts that silently fail to
  # forward jobs, and it has been deprecated upstream in favour of
  # permanent driverless queues. Disabling it leaves a single, declared,
  # reproducible queue that survives reboots and rebuilds.
  services.printing.enable = true;
  services.printing.browsed.enable = false;

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_MFC_L3720CDW";
        location = "Office";
        deviceUri = "ipp://192.168.100.73/ipp/print";
        model = "everywhere";
        ppdOptions = {
          PageSize = "Letter";
        };
      }
    ];
    ensureDefaultPrinter = "Brother_MFC_L3720CDW";
  };

  # The ensure-printers oneshot calls `lpadmin`, which must contact
  # the printer over the network to fetch its driverless IPP
  # attributes (model = "everywhere"). The upstream unit is ordered
  # only After=cups.service, so at boot it can run before the network
  # is up — lpadmin errors and the queue is never created. Order it
  # after the network (and avahi, kept for any future .local URI) so
  # the lookup actually works.
  #
  # Belt-and-suspenders: treat exit 1 as success so a genuinely offline
  # printer (asleep / off-network) at switch time can't fail the whole
  # `nixos-rebuild switch` (status 4), which would also wedge the weekly
  # unattended upgrade (see modules/upgrade.nix). The queue is persistent
  # once created, so it only needs one successful run.
  #
  # Tradeoff: SuccessExitStatus also masks genuine lpadmin
  # misconfigurations that exit 1 (bad option, unknown model). If the
  # queue silently stops appearing, run `ensure-printers-start` by hand
  # (as root) to see the real error.
  systemd.services.ensure-printers = {
    after = ["network-online.target" "avahi-daemon.service" "nss-lookup.target"];
    wants = ["network-online.target" "avahi-daemon.service"];
    serviceConfig.SuccessExitStatus = "0 1";
  };

  # ── Audio (PipeWire) ───────────────────────────────────────────────
  # PipeWire replaces PulseAudio and provides low-latency audio,
  # screen sharing, and Bluetooth codec support. The PulseAudio
  # compatibility layer (pulse.enable) lets legacy apps work unchanged.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # Realtime scheduling for PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # Needed by 32-bit games (Steam/Proton)
    pulse.enable = true;
  };

  # ── SSH server ─────────────────────────────────────────────────────
  # https://wiki.nixos.org/wiki/SSH
  #
  # Hardened: password and keyboard-interactive auth are disabled,
  # root login is forbidden. Only key-based authentication is accepted.
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Fail2ban ───────────────────────────────────────────────────────
  # https://wiki.nixos.org/wiki/Fail2ban
  #
  # Monitors SSH logs and bans IPs after repeated failed login attempts,
  # reducing brute-force exposure.
  services.fail2ban.enable = true;

  # ── Niri desktop plumbing ──────────────────────────────────────────
  # GNOME/KDE pull these in transitively; on niri we have to enable
  # them explicitly or a handful of things silently don't work.

  # Avahi — mDNS / DNS-SD. Without it, Brother network printers do not
  # show up in CUPS auto-discovery (you'd have to add them by raw IP),
  # `.local` hostnames don't resolve, and Chromecast/AirPlay targets
  # are invisible. `nssmdns4` wires mDNS into glibc's name resolution
  # so ordinary tools (ping, curl, browsers) can hit `.local` names.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Prevent stale PID file from blocking avahi-daemon restarts during
  # switch-to-configuration. The old daemon sometimes dies without
  # cleaning up /run/avahi-daemon/pid, causing the new instance to
  # refuse to start.
  systemd.services.avahi-daemon.serviceConfig.ExecStartPre = "-/run/current-system/sw/bin/rm -f /run/avahi-daemon/pid";

  # gvfs — virtual filesystem layer used by Nautilus (and anything
  # GIO-based). Without it Nautilus has no Trash, can't browse SMB /
  # SFTP / MTP, and won't show mountable volumes in the sidebar.
  services.gvfs.enable = true;

  # udisks2 — powers click-to-mount for removable drives in Nautilus
  # and lets non-root users mount USB sticks / external disks without
  # editing fstab.
  services.udisks2.enable = true;

  # ── Local LLMs (llama-swap + llama.cpp) ────────────────────────────
  # llama-swap proxies an OpenAI-compatible API on 127.0.0.1:11434
  # (Ollama's port, so Pi needs no reconfiguration) and hot-swaps
  # llama-server instances on demand: whichever model name a request
  # asks for gets loaded, unloading the other. Models are lazy-loaded
  # on first request after boot. VRAM budget: keep ~1 GiB free on the
  # 16 GB 5080 for desktop/browser.
  #
  # Model files live on the NVMe in /var/lib/llms (world-readable; the
  # service runs as a DynamicUser). Loads are ~5-10 s from NVMe.
  systemd.tmpfiles.rules = ["d /var/lib/llms 0755 bws428 users -"];

  systemd.services.llama-swap = let
    llama = pkgs.llama-cpp.override {cudaSupport = true;};

    # Flags shared by every model. Knobs:
    #   --gpu-layers 99      all attention/dense weights on GPU (small);
    #                        VRAM is tuned per-model with --n-cpu-moe
    #   --no-mmap            load weights fully into RAM, not disk-mmap
    #   --flash-attn on      faster + less VRAM at long context
    #   --jinja              model's embedded chat template; REQUIRED for
    #                        OpenAI-style tool calling in Pi
    #   --ubatch-size        PREFILL SPEED knob (repo/file ingestion);
    #                        halve to 1024 if VRAM gets tight
    #   --threads-batch 16   prefill on all SMT threads (compute-bound);
    #                        decode stays at default 8 (bandwidth-bound)
    #   --cache-reuse 256    reuse KV chunks on shifted prompts
    #
    # KV quantization (--cache-type-k/v) is PER-MODEL, not shared:
    # whether the CUDA flash-attention kernel supports a quantized KV
    # combo depends on the model's head layout. If unsupported it
    # silently falls back to CPU attention — no error, just a ~50x
    # slowdown that worsens with context depth (coder went 30 -> 5,153
    # tok/s prefill when q4_0 V was lifted, 2026-08-07). Symptom: slow
    # + GPU idle + degrades with fill. Test any new combo before trust.
    commonFlags =
      "--host 127.0.0.1 --port \${PORT}"
      + " --gpu-layers 99 --no-mmap"
      + " --flash-attn on --jinja"
      + " --batch-size 2048 --ubatch-size 2048"
      + " --threads-batch 16 --cache-reuse 256";

    # Per-model knobs:
    #   --n-cpu-moe N   MAIN VRAM KNOB: layers of MoE experts kept on CPU
    #                   (35B ≈ 450 MiB/layer, coder ≈ 250 MiB/layer);
    #                   lower = faster decode; -2 while >1 GiB VRAM free
    #   --ctx-size      context window; lowering frees VRAM for experts
    #                   (coder KV ≈ 3.34 GiB per 64K at q8/q8)
    #
    # Also prefer K-quant GGUFs (Q3_K/Q4_K/UD-*_K_*) over i-quants
    # (IQ2/IQ3/...) whenever experts live on CPU: i-quant CPU matmul
    # is markedly slower (documented llama.cpp behavior).
    #
    # Benchmarks 2026-08-07 (7.4K-token prompt, cold): 35B 269 pp /
    # 41 tg; coder@128K 4,876 pp / 74 tg. Coder prefill is GPU-streamed
    # (large-batch op offload), so high n-cpu-moe barely hurts it.
    swapConfig = pkgs.writeText "llama-swap.yaml" ''
      healthCheckTimeout: 600

      # Naming: <vendor><gen>-<level>. Level = how much thought per
      # token you're buying: think > code (lite) > sprint. Aliases keep
      # the original ids routing for old sessions/scripts.
      models:
        "qwen3.6-think":
          name: "Think — Qwen3.6-35B · 256K"
          aliases:
            - "qwen3.6-35b"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf
            --cache-type-k q8_0 --cache-type-v q4_0
            --ctx-size 262144
            --n-cpu-moe 22

        # Q4_K_M: best coder quality (18.6 GB); more experts on CPU to
        # pay for it. Tune n-cpu-moe down while >1 GiB VRAM stays free.
        # q8_0 V (NOT q4_0) on all coder entries: q4_0 V triggers the
        # CPU-attention fallback on this arch — see KV note above.
        "qwen3-code":
          name: "Code — Qwen3-Coder-30B Q4 · 128K"
          aliases:
            - "qwen3-coder-30b-q4"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
            --cache-type-k q8_0 --cache-type-v q8_0
            --ctx-size 131072
            --n-cpu-moe 33

        # Q3_K_XL of the same coder: A/B rival for qwen3-code. If the
        # quality gap is imperceptible after real use, one of them goes.
        "qwen3-code-lite":
          name: "Code Lite — Qwen3-Coder-30B Q3 · 128K"
          aliases:
            - "qwen3-coder-30b"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen3-Coder-30B-A3B-Instruct-UD-Q3_K_XL.gguf
            --cache-type-k q8_0 --cache-type-v q8_0
            --ctx-size 131072
            --n-cpu-moe 26

        # Same GGUF as code-lite; trades context for faster decode.
        "qwen3-sprint":
          name: "Sprint — Qwen3-Coder-30B Q3 · 64K"
          aliases:
            - "qwen3-coder-30b-fast"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen3-Coder-30B-A3B-Instruct-UD-Q3_K_XL.gguf
            --cache-type-k q8_0 --cache-type-v q8_0
            --ctx-size 65536
            --n-cpu-moe 12
    '';
  in {
    description = "llama-swap multi-model LLM proxy";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    environment.LLAMA_CACHE = "/var/cache/llama-swap";

    serviceConfig = {
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config ${swapConfig} --listen 127.0.0.1:11434";
      Restart = "on-failure";
      RestartSec = 5;

      # Sandbox mirrors the upstream services.llama-cpp unit, which is
      # proven to work with CUDA on this box (PrivateDevices must stay
      # false for GPU access).
      DynamicUser = true;
      StateDirectory = "llama-swap";
      CacheDirectory = "llama-swap";
      WorkingDirectory = "/var/lib/llama-swap";
      PrivateDevices = false;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      # "all" (not "pid"): llama-swap polls /proc/meminfo for its stats;
      # "pid" blocks that and spams the journal every 5s.
      ProcSubset = "all";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      SystemCallArchitectures = "native";
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = ["@system-service" "~@privileged"];
    };
  };
}
