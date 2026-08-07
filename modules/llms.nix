{
  config,
  pkgs,
  lib,
  ...
}: {
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

    # llama.cpp build from the PrismML fork — required for ternary
    # (Q2_0) weights (Ternary Bonsai 27B). Upstream llama.cpp merged
    # CPU/Metal Q2_0 but CUDA support landed later; the PrismML fork
    # is the proven serving path for this model today.
    llama-bonsai = let
      src = pkgs.fetchFromGitHub {
        owner = "PrismML-Eng";
        repo = "llama.cpp";
        rev = "62061f91088281e65071cc38c5f69ee95c39f14e";
        hash = "sha256-CH4k2ga+NDvjb2lzxdi9OtJrwaowbt9mIcOgsCfserI=";
        leaveDotGit = true;
        postFetch = ''
          git -C "$out" rev-parse --short HEAD > $out/COMMIT
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };
      bonsaiStdenv = pkgs.cudaPackages.backendStdenv;
    in
      bonsaiStdenv.mkDerivation (finalAttrs: {
        pname = "llama-cpp-bonsai";
        version = "62061f9";
        inherit src;

        nativeBuildInputs = with pkgs; [
          cmake
          ninja
          pkg-config
          cudaPackages.cuda_nvcc
          autoAddDriverRunpath
        ];

        buildInputs = with pkgs; [
          openssl
          cudaPackages.cuda_cudart
          cudaPackages.libcublas
        ];

        cmakeFlags = with pkgs; [
          (lib.cmakeBool "GGML_NATIVE" false)
          (lib.cmakeBool "LLAMA_BUILD_EXAMPLES" false)
          (lib.cmakeBool "LLAMA_BUILD_SERVER" true)
          (lib.cmakeBool "LLAMA_BUILD_TESTS" false)
          (lib.cmakeBool "BUILD_SHARED_LIBS" true)
          (lib.cmakeBool "GGML_CUDA" true)
          (lib.cmakeBool "LLAMA_OPENSSL" true)
          (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
        ];

        preConfigure = ''
          prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=$(cat COMMIT)"
        '';

        postInstall = ''
          ln -sf $out/bin/llama-cli $out/bin/llama
          mkdir -p $out/include
          cp $src/include/llama.h $out/include/
        '';

        doCheck = false;
      });

    # Flags shared by every model. Knobs:
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
      + " --no-mmap"
      + " --flash-attn on --jinja"
      + " --batch-size 2048 --ubatch-size 2048"
      + " --threads-batch 16 --cache-reuse 256";

    # Per-model knobs:
    #   --gpu-layers    99 on MoE entries (VRAM tuned via --n-cpu-moe);
    #                   omit on dense entries so auto-fit sizes to free VRAM
    #   --n-cpu-moe N   MAIN VRAM KNOB: layers of MoE experts kept on CPU
    #                   (35B ≈ 450 MiB/layer);
    #                   lower = faster decode; -2 while >1 GiB VRAM free
    #   --ctx-size      context window; lowering frees VRAM for experts
    #
    # Also prefer K-quant GGUFs (Q3_K/Q4_K/UD-*_K_*) over i-quants
    # (IQ2/IQ3/...) whenever experts live on CPU: i-quant CPU matmul
    # is markedly slower (documented llama.cpp behavior).
    #
    # Benchmarks 2026-08-07 (13.2K-token prompt, cold): 35B 269 pp /
    # 41 tg; 27B-fast 1332 pp / 19 tg (25 tg short ctx); 9B-sprint
    # 6940 pp / 89 tg. Prefill streams CPU-parked experts through the
    # GPU in large batches, so high n-cpu-moe barely hurts prefill.
    swapConfig = pkgs.writeText "llama-swap.yaml" ''
      healthCheckTimeout: 600

      # Naming: <vendor><gen>-<level>. Level = how much thought per
      # token you're buying. Aliases keep the original ids routing for
      # old sessions/scripts.
      models:
        "qwen3.6-think":
          name: "Think — Qwen3.6-35B · 256K"
          aliases:
            - "qwen3.6-35b"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf
            --gpu-layers 99
            --cache-type-k q8_0 --cache-type-v q4_0
            --ctx-size 262144
            --n-cpu-moe 22

        # Dense hybrid (GDN), fits VRAM whole at Q3_K_S; no --gpu-layers
        # so auto-fit adapts to free VRAM. MTP drafting ~1.7x decode.
        "qwen3.6-fast":
          name: "Fast — Qwen3.6-27B MTP · 64K"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen3.6-27B-Q3_K_S.gguf
            --parallel 1 --ctx-size 65536 --ubatch-size 1024
            --spec-type draft-mtp --spec-draft-n-max 2
            --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0

        # Ternary Bonsai 27B: ~7.2 GB dense hybrid at 1.71 bpw.
        # Fits whole in VRAM with headroom; 4-bit KV keeps long
        # contexts practical on a 16 GB card.
        "bonsai-27b":
          name: "Bonsai — Ternary 27B · 64K"
          aliases:
            - "bonsai"
          cmd: >
            ${llama-bonsai}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Ternary-Bonsai-27B-Q2_0.gguf
            --parallel 1 --ctx-size 65536
            --cache-type-k q4_0 --cache-type-v q4_0
            --temp 0.7 --top-p 0.95 --top-k 20 --min-p 0.0

        # Dense hybrid 9B at Q8_0, fully VRAM-resident; the speed tier.
        "qwen3.5-sprint":
          name: "Sprint — Qwen3.5-9B Q8 · 128K"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen_Qwen3.5-9B-Q8_0.gguf
            --parallel 1 --ctx-size 131072
            --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0
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
