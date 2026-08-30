{
  pkgs,
  lib,
  ...
}: {
  # ── Local LLM (llama-swap + llama.cpp) ─────────────────────────────
  # OpenAI-compatible proxy. The model loads on first use and unloads
  # when idle. Every model is pinned to the RTX 3090 (24 GB) alone via
  # --device CUDA1; the 5080 drives the display and never runs compute
  # (see modules/nvidia.nix), so inference can't freeze the desktop.
  # Model files: /var/lib/llms.
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
        # but only 3 billion active params. Tiny KV cache (11 attention
        # layers) keeps its footprint small enough to run 128K on the
        # 3090 alone.
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
          # Pin to the 3090 only; the 5080 must never run CUDA (Xid 8
          # history). Single card, so no --split-mode / --fit needed.
          --device CUDA1 --n-gpu-layers -1
          # Keep V at q8_0 or it falls back to slow CPU
          --cache-type-k q8_0 --cache-type-v q8_0
          # 128K on 24 GB: ~20.75 GiB weights + ~1.4 GiB KV + buffers
          # ≈ 22.2 GiB, ~1.4 GiB headroom. 256K no longer fits one card.
          --ctx-size 131072
        '';
      };

      models."qwen3.8-27b" = {
        name = "Qwen3.8 27B";
        # Unloads after 15 min idle (900s) to free VRAM.
        ttl = 900;

        # Qwen3.8 27B (Q4_K_M)
        # https://huggingface.co/bartowski/Qwen_Qwen3.8-27B-GGUF
        # Dense hybrid (SSM + full attention every 4th layer). 17.8 GB.
        # Benchmarked +0.5% PPL vs Q5_K_M.
        cmd = ''
          ${lib.getExe' llama "llama-server"}
          --host 127.0.0.1 --port ''${PORT}
          --no-mmap --flash-attn on --jinja
          # ubatch 1024 (not 2048): measured *faster* prompt reading
          # (1499 vs 1324 tok/s). Gen speed within noise.
          --batch-size 2048 --ubatch-size 1024
          --threads-batch 16
          --model /var/lib/llms/Qwen3.8-27B-Q4_K_M.gguf
          # Pin to the 3090 only; the 5080 must never run CUDA.
          --device CUDA1 --n-gpu-layers -1
          # V cache must stay q8_0 — q4_0 falls back to slow CPU.
          --cache-type-k q8_0 --cache-type-v q8_0
          # 96K on 24 GB with MTP: ~16.55 GiB weights + ~3.2 GiB KV +
          # ~2.5 GiB MTP draft ≈ 22.2 GiB, ~1.4 GiB headroom. Drop the
          # two --spec-* flags to push ctx to 128K instead (loses ~60
          # -> ~37 tok/s).
          --ctx-size 98304
          # MTP speculative decoding via the model's built-in NextN
          # head (blk.64): measured 37 -> ~60 tok/s generation.
          # draft-2 beats draft-3 on acceptance-vs-speed tradeoff.
          --spec-type draft-mtp --spec-draft-n-max 2
        '';
      };
    };
  };
}
