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

      models."qwen3.6-35b" = {
        name = "Qwen3.6 35B";
        # Unloads after 15 min idle (900s) to free VRAM.
        ttl = 900;

        # Qwen3.6 35B A3B (Q4_K_M)
        # https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF
        # Mixture-of-experts (MoE) model with 35 billion total parameters
        # but only 3 billion active params. Fits entirely in the 40 GB of
        # combined VRAM, so no CPU offload is needed.
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
          --gpu-layers 99
          # Split layers across both GPUs. Unset --tensor-split means
          # llama.cpp splits by free VRAM, so the 24 GB 3090 gets a
          # proportionally larger share than the 16 GB 5080.
          --split-mode layer
          # Keep V at q8_0 or it falls back to slow CPU
          --cache-type-k q8_0 --cache-type-v q8_0
          --ctx-size 262144
        '';
      };

      models."qwen3.8-27b" = {
        name = "Qwen3.8 27B";
        # Unloads after 15 min idle (900s) to free VRAM.
        ttl = 900;

        # Qwen3.8 27B (Q5_K_M)
        # https://huggingface.co/bartowski/Qwen_Qwen3.8-27B-GGUF
        # Dense hybrid model (SSM layers + full attention every 4th
        # layer). KV cache ~4.8 GB at 128K ctx, ~19 GB weights (~24 GB
        # combined), leaving real headroom on the 16 GB display GPU.
        # 256K ctx grew KV to ~9.5 GB and OOM'd the 5080.
        cmd = ''
          ${lib.getExe' llama "llama-server"}
          --host 127.0.0.1 --port ''${PORT}
          --no-mmap --flash-attn on --jinja
          # ubatch 1024 (not 2048): measured *faster* prompt reading
          # (1499 vs 1324 tok/s) and leaves more VRAM headroom on the
          # display GPU. Gen speed within noise.
          --batch-size 2048 --ubatch-size 1024
          --threads-batch 16
          --model /var/lib/llms/Qwen3.8-27B-Q5_K_M.gguf
          --gpu-layers 99
          # Split by *free* VRAM — the 5080 also drives the displays,
          # so a hardcoded --tensor-split would overcommit it.
          --split-mode layer
          --cache-type-k q8_0 --cache-type-v q8_0
          --ctx-size 131072
          # MTP speculative decoding via the model's built-in NextN
          # head (blk.64): measured 37 -> ~60 tok/s generation.
          # draft-2 beats draft-3 on acceptance-vs-speed tradeoff.
          --spec-type draft-mtp --spec-draft-n-max 2
        '';
      };
    };
  };
}
