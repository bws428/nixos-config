{
  config,
  pkgs,
  lib,
  ...
}: {
  # ── Local LLMs (llama-swap + llama.cpp) ────────────────────────────
  # OpenAI-compatible proxy on 127.0.0.1:11434 (Ollama's port, so Pi
  # needs no reconfiguration). A request's model name picks which
  # llama-server instance runs; models lazy-load on first request.
  # - VRAM budget: keep ~1 GiB of the 16 GB 5080 free for the desktop
  # - model files: /var/lib/llms on NVMe (world-readable; service is a
  #   DynamicUser); loads ~5-10 s
  systemd.tmpfiles.rules = ["d /var/lib/llms 0755 bws428 users -"];

  systemd.services.llama-swap = let
    llama = pkgs.llama-cpp.override {cudaSupport = true;};

    # PrismML llama.cpp fork: CUDA kernels for ternary (Q2_0) weights,
    # which this pin of upstream only runs on CPU/Metal.
    llama-bonsai = let
      src = pkgs.fetchFromGitHub {
        owner = "PrismML-Eng";
        repo = "llama.cpp";
        rev = "62061f91088281e65071cc38c5f69ee95c39f14e";
        hash = "sha256-zLxB5UKnCTCw/okB+L8u1VtM1o2yVjVYTlTBgL/BsaM=";
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

    # Shared flags:
    # - --no-mmap: load weights fully into RAM, not disk-mmap
    # - --flash-attn on: faster + less VRAM at long context
    # - --jinja: embedded chat template; required for tool calling in Pi
    # - --ubatch-size: prefill speed; halve to 1024 if VRAM gets tight
    # - --threads-batch 16: prefill on all SMT threads; decode default 8
    # - --cache-reuse 256: reuse KV chunks on shifted prompts
    #
    # KV quantization (--cache-type-k/v) is PER-MODEL: an unsupported
    # combo makes CUDA flash-attn silently fall back to CPU — no error,
    # ~50x slower, worsens with depth (symptom: slow + GPU idle).
    # Benchmark at depth before trusting any new combo.
    commonFlags =
      "--host 127.0.0.1 --port \${PORT}"
      + " --no-mmap"
      + " --flash-attn on --jinja"
      + " --batch-size 2048 --ubatch-size 2048"
      + " --threads-batch 16 --cache-reuse 256";

    # Per-model knobs:
    # - --gpu-layers 99 on MoE entries only; dense entries omit it so
    #   auto-fit sizes layers to free VRAM
    # - --n-cpu-moe N: MoE expert layers on CPU (35B ≈ 450 MiB/layer).
    #   Treat as pure VRAM slack: on A3B it costs little decode, and
    #   prefill streams CPU-parked experts through the GPU regardless
    # - --ctx-size: lowering frees VRAM
    # - prefer K-quant GGUFs over i-quants (IQ2/IQ3/...) whenever
    #   experts live on CPU: i-quant CPU matmul is markedly slower
    #
    # Measured: think 3508 pp / 70 tg @48K (81 tg short ctx);
    # bonsai 2112 pp / 66 tg @13K (41 tg @54K, 27 tg @107K).
    swapConfig = pkgs.writeText "llama-swap.yaml" ''
      healthCheckTimeout: 600

      # Aliases keep retired ids routing (old Pi sessions/scripts).
      models:
        # q4_0 V trips the CPU flash-attn fallback on this model —
        # keep V at q8_0. n-cpu-moe 27 makes room for the bigger V.
        "qwen3.6-35b":
          name: "Qwen3.6 35B"
          aliases:
            - "qwen3.6-think"
          cmd: >
            ${llama}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf
            --gpu-layers 99
            --cache-type-k q8_0 --cache-type-v q8_0
            --ctx-size 262144
            --n-cpu-moe 27

        # Dense hybrid at 1.71 bpw; whole model + 256K KV ≈ 13.9 GiB,
        # fits the card whole (q4_0 KV ≈ 1.6 GiB per 64K).
        "bonsai-27b":
          name: "Bonsai 27B"
          aliases:
            - "bonsai"
          cmd: >
            ${llama-bonsai}/bin/llama-server ${commonFlags}
            --model /var/lib/llms/Ternary-Bonsai-27B-Q2_0.gguf
            --parallel 1 --ctx-size 262144
            --cache-type-k q4_0 --cache-type-v q4_0
            --temp 0.7 --top-p 0.95 --top-k 20 --min-p 0.0
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

      # Sandbox mirrors the upstream services.llama-cpp unit;
      # PrivateDevices must stay false for GPU access.
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
      # "all": llama-swap polls /proc/meminfo; "pid" spams the journal.
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
