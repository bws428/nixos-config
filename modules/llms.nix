{
  pkgs,
  lib,
  ...
}: {
  # ── Local LLM (llama-swap + llama.cpp) ─────────────────────────────
  # OpenAI-compatible proxy on 127.0.0.1:11434 (Ollama's port, so Pi
  # and OpenCode need no reconfiguration). The model lazy-loads on the
  # first request and unloads again once idle, so the card is free for
  # games whenever the LLM isn't in use.
  # - VRAM budget: keep ~1 GiB of the 16 GB 5080 free for the desktop
  # - model files: /var/lib/llms on NVMe (world-readable; the service
  #   is a DynamicUser); loads ~5-10 s
  systemd.tmpfiles.rules = ["d /var/lib/llms 0755 bws428 users -"];

  services.llama-swap = let
    llama = pkgs.llama-cpp.override {cudaSupport = true;};
  in {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 11434;

    settings = {
      healthCheckTimeout = 600;

      models."qwen3.6-35b" = {
        name = "Qwen3.6 35B";
        # Keeps the retired id routing for old Pi sessions and scripts.
        aliases = ["qwen3.6-think"];
        # Unload 15 min after the last request, freeing ~14 GiB of VRAM.
        ttl = 900;

        # Qwen3.6 35B A3B, from
        # https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF
        #
        # KV quantization (--cache-type-k/v) is per-model: an unsupported
        # combo makes CUDA flash-attn silently fall back to CPU — no
        # error, ~50x slower, worsens with depth (symptom: slow + GPU
        # idle). Benchmark at depth before trusting any new combo.
        cmd = ''
          ${lib.getExe' llama "llama-server"}
          --host 127.0.0.1 --port ''${PORT}
          # --no-mmap: load weights fully into RAM, not disk-mmap
          # --flash-attn: faster + less VRAM at long context
          # --jinja: embedded chat template, required for tool calling
          --no-mmap --flash-attn on --jinja
          # The GGUF ships Qwen's trained draft head (blk.40.nextn); its guesses
          # are verified in one batched pass, which costs ~0.2 ms/token here.
          --spec-type draft-mtp
          # --ubatch-size drives prefill speed; halve if VRAM gets tight
          --batch-size 2048 --ubatch-size 2048
          # prefill on all SMT threads; decode stays on the default 8
          --threads-batch 16 --cache-reuse 256
          --model /var/lib/llms/Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf
          --gpu-layers 99
          # q4_0 V trips the CPU fallback on this model — keep V at q8_0
          --cache-type-k q8_0 --cache-type-v q8_0
          --ctx-size 262144
          # MoE expert layers on CPU (~450 MiB/layer). Treat as pure VRAM
          # slack: on an A3B it costs little decode, and prefill streams
          # CPU-parked experts through the GPU regardless. 27 makes room
          # for the larger q8_0 V-cache.
          --n-cpu-moe 27
        '';
      };
    };
  };
}
