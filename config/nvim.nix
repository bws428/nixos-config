{ pkgs, ... }:

{
  # ── Neovim (LazyVim) ───────────────────────────────────────────────
  # Home Manager installs the binary and LazyVim's runtime dependencies;
  # the config itself lives at ~/.config/nvim and is managed by
  # lazy.nvim (the LazyVim starter, cloned manually — see note below).
  #
  # Bootstrap on a fresh machine:
  #   git clone https://github.com/LazyVim/starter ~/.config/nvim
  #   rm -rf ~/.config/nvim/.git
  #   nvim
  #
  # We intentionally do NOT manage ~/.config/nvim through xdg.configFile
  # so that lazy.nvim can write its lockfile and plugin cache there.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Providers LazyVim plugins commonly expect.
    withNodeJs = true;
    withPython3 = true;
    # LazyVim doesn't use the Ruby provider; adopt the new HM default
    # explicitly to silence the pre-26.05 legacy-default warning.
    withRuby = false;

    # Tools LazyVim invokes at runtime. Putting them in extraPackages
    # guarantees they're on Neovim's PATH without polluting the user
    # environment.
    extraPackages = with pkgs; [
      gcc            # C compiler for nvim-treesitter
      tree-sitter    # tree-sitter CLI (parser builds)
      ripgrep        # telescope live_grep
      fd             # telescope file finder
      fzf            # fuzzy matcher
      lazygit        # lazygit.nvim integration
      unzip          # mason package extraction
      wget
      curl
    ];
  };
}
