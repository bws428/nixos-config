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

  # ── Local LLM (llama.cpp) ──────────────────────────────────────────
  # Replaces Ollama. llama-server exposes an OpenAI-compatible API on
  # 127.0.0.1:11434 so Pi needs no reconfiguration.
  #
  # Model: bartowski/Qwen_Qwen3.6-35B-A3B-GGUF Q4_K_M (~22.3 GB).
  # The MoE architecture activates only ~3B params per token, making
  # partial GPU offloading viable even on a 16 GB 5080. The remaining
  # weights live in system RAM; --n-cpu-moe routes expert switching
  # through the CPU.
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };

    settings = {
      host = "127.0.0.1";
      port = 11434;               # match Ollama's port
      model = "/mnt/seagate500/llms/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf";

      # Layer offloading: explicit cap leaves GPU headroom for KV cache.
      # The model has ~40 layers; 32 on GPU ≈ 16 GB weights, leaving
      # ~1-2 GB for KV cache and CUDA overhead. Increase if nvtop shows
      # spare VRAM (try 36, then 38). Decrease if you see OOM.
      gpu-layers = 32;

      # MoE expert routing: keeps routed expert weights of the first 36
      # layers on CPU. This is the video's core trick — the expert
      # matrices are 90% of params but only ~3B are active per token.
      n-cpu-moe = 36;

      no-mmap = true;             # load weights into RAM, not disk-mmap
      ctx-size = 262144;          # 256K context window (model's trained limit)

      # KV-cache quantization: q4_0 gives maximum VRAM headroom.
      # The video used no explicit KV quant (default fp16), but on a
      # 16 GB card with 128K context we need the space. If output
      # quality feels degraded, try q8_0 instead.
      cache-type-k = "q4_0";
      cache-type-v = "q4_0";
      flash-attn = "on";          # faster + less VRAM on long contexts

      # --mlock is omitted for now: the NixOS service runs as a
      # DynamicUser without CAP_IPC_LOCK. On a desktop with ample RAM
      # it is unnecessary. To enable later, uncomment below AND add a
      # systemd.services.llama-cpp.serviceConfig override for
      # AmbientCapabilities / CapabilityBoundingSet.
      # mlock = true;
    };
  };
}
