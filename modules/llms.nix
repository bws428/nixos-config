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
        cmd = ''
          ${lib.getExe' llama "llama-server"}
          --host 127.0.0.1 --port ''${PORT}
          --no-mmap --flash-attn on --jinja
          # ubatch 512 (not 1024): the fused-GDN graph reserve needs more
          # VRAM headroom than 1024 leaves at 96K ctx + MTP. When reserve
          # fails, llama.cpp silently spills the GDN ops to CPU (upstream
          # #27162) and gen collapses 60 -> ~13 tok/s. 1024 was otherwise
          # the pp sweet spot (1499 vs 1324 tok/s at 2048) — revisit if
          # ctx shrinks.
          --batch-size 2048 --ubatch-size 512
          --threads-batch 16
          --model /var/lib/llms/Qwen3.8-27B-Q4_K_M.gguf
          # Pin to the 3090 only; the 5080 must never run CUDA.
          --device CUDA1 --n-gpu-layers -1
          # V cache must stay q8_0 — q4_0 falls back to slow CPU.
          --cache-type-k q8_0 --cache-type-v q8_0
          # 128K on 24 GB without MTP: ~16.55 GiB weights + ~4.3 GiB KV
          # + compute reserve. MTP had to go: at >=96K ctx the draft
          # (~2.5 GiB) leaves too little VRAM for the fused-GDN graph
          # reserve and llama.cpp silently spills GDN to CPU (upstream
          # #27162) — ubatch 512 alone recovered only 42 of 60 tok/s.
          # Builder's workload (spec-kit execution) compacts well past
          # 64K, so window beats speed: measured ~37 tok/s here vs ~60
          # with MTP at 96K. ubatch stays 512 as headroom insurance.
          --ctx-size 131072
        '';
      };
    };
  };
}
