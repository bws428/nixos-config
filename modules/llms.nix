{
  pkgs,
  lib,
  ...
}: {
  # ── Local LLM (llama-swap + llama.cpp) ─────────────────────────────
  # OpenAI-compatible proxy. The model loads on first use and unloads
  # when idle, so the cards are free for games. The model spans both
  # GPUs (16 GB RTX 5080 + 24 GB RTX 3090 = 40 GB VRAM), with layers
  # split across them. Model files: /var/lib/llms.
  systemd.tmpfiles.rules = ["d /var/lib/llms 0755 bws428 users -"];

  services.llama-swap = let
    llama = pkgs.llama-cpp.override {cudaSupport = true;};
  in {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8080;

    settings = {
      healthCheckTimeout = 600;
      # Surface llama-server's own output (model load log, CUDA errors) to
      # the journal. Default 'proxy' discards the upstream process output.
      logToStdout = "both";

      models."qwen3.6-35b" = {
        name = "Qwen3.6 35B";
        # Unloads after 15 min idle (900s) to free VRAM.
        ttl = 900;

        # Qwen3.6 35B A3B (Q4_K_M)
        # https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF
        # Mixture-of-experts (MoE) model with 35 billion total parameters
        # but only 3 billion active params. Context pinned at 192K with
        # --fit reserving headroom on the 5080; 256K overcommitted both
        # cards and froze niri (2026-08-22).
        cmd = ''
          ${lib.getExe' llama "llama-server"}
          --host 127.0.0.1 --port ''${PORT}
          # no-mmap: load weights into RAM 
          # flash-attn: faster, uses less VRAM
          # jinja: needed for tool calls
          --no-mmap --flash-attn on --jinja
          # Bigger = faster prompt reading; shrink if VRAM is tight
          --batch-size 2048 --ubatch-size 2048
          # Use all threads for prompt reading
          --threads-batch 16 --cache-reuse 256
          --model /var/lib/llms/Qwen3.6-35B-A3B-Q4_K_M.gguf
          # --fit auto-places layers/KV to leave the target margin free on
          # each GPU: 2 GiB on the 5080 (it also drives the displays) and
          # 1 GiB on the 3090. Replaces the free-VRAM split, which grabbed
          # everything and left the desktop nothing to grow into.
          --split-mode layer
          # Keep V at q8_0 or it falls back to slow CPU
          --cache-type-k q8_0 --cache-type-v q8_0
          --ctx-size 196608
          --fit on --fit-target 2048,1024
        '';
      };

      models."qwen3.8-27b" = {
        name = "Qwen3.8 27B";
        # Unloads after 15 min idle (900s) to free VRAM.
        ttl = 900;

        # Qwen3.8 27B (Q4_K_M)
        # https://huggingface.co/bartowski/Qwen_Qwen3.8-27B-GGUF
        # Dense hybrid model (SSM layers + full attention every 4th
        # layer). 17.8 GB weights. Context pinned at 192K with --fit
        # reserving headroom on the 5080; 256K overcommitted both cards
        # and froze niri (2026-08-22). Benchmarked +0.5% PPL vs Q5_K_M.
        cmd = ''
          ${lib.getExe' llama "llama-server"}
          --host 127.0.0.1 --port ''${PORT}
          --no-mmap --flash-attn on --jinja
          # ubatch 1024 (not 2048): measured *faster* prompt reading
          # (1499 vs 1324 tok/s) and leaves more VRAM headroom on the
          # display GPU. Gen speed within noise.
          --batch-size 2048 --ubatch-size 1024
          --threads-batch 16
          --model /var/lib/llms/Qwen3.8-27B-Q4_K_M.gguf
          # --fit auto-places layers/KV to leave the target margin free on
          # each GPU: 2 GiB on the 5080 (it also drives the displays) and
          # 1 GiB on the 3090. Replaces the free-VRAM split, which grabbed
          # everything and left the desktop nothing to grow into.
          --split-mode layer
          # V cache must stay q8_0 — q4_0 falls back to slow CPU.
          --cache-type-k q8_0 --cache-type-v q8_0
          --ctx-size 196608
          --fit on --fit-target 2048,1024
          # MTP speculative decoding via the model's built-in NextN
          # head (blk.64): measured 37 -> ~60 tok/s generation.
          # draft-2 beats draft-3 on acceptance-vs-speed tradeoff.
          --spec-type draft-mtp --spec-draft-n-max 2
        '';
      };
    };
  };
}
