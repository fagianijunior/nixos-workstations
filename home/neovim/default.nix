{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Disable built-in providers — LSPs managed via extraPackages
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      # Theme
      catppuccin-nvim

      # Fuzzy finder
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim

      # LSP
      nvim-lspconfig

      # Completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp_luasnip
      cmp-cmdline

      # Snippets
      luasnip
      friendly-snippets

      # Treesitter
      (nvim-treesitter.withPlugins (p: [
        p.lua
        p.nix
        p.python
        p.typescript
        p.javascript
        p.tsx
        p.rust
        p.go
        p.bash
        p.json
        p.yaml
        p.toml
        p.markdown
        p.html
        p.css
        p.vim
        p.vimdoc
        p.terraform
        p.hcl
        p.ruby
        p.php
        p.dockerfile
        p.sql
        p.regex
        p.diff
        p.gitcommit
      ]))
      nvim-treesitter-textobjects

      # Git integration
      gitsigns-nvim

      # Icons
      mini-icons
      nvim-web-devicons

      # File explorer
      neo-tree-nvim
      nui-nvim

      # Keybinding discovery
      which-key-nvim

      # Statusline
      lualine-nvim

      # Code formatting
      conform-nvim

      # Terminal integration
      toggleterm-nvim

      # Indentation guides
      indent-blankline-nvim

      # Auto pairs
      nvim-autopairs

      # Commenting
      comment-nvim

      # Buffer tabs
      bufferline-nvim
    ];

    extraPackages = with pkgs; [
      # Telescope dependencies
      ripgrep
      fd

      # Treesitter CLI (needed by nvim-treesitter for parser compilation)
      tree-sitter

      # Language servers
      nixd
      terraform-ls
      rubyPackages.solargraph
      intelephense
      pyright
      lua-language-server
      bash-language-server
      dockerfile-language-server

      # Formatters
      nixpkgs-fmt
      prettier
      stylua
      rubocop
      php84Packages.php-cs-fixer
      black
      shfmt
    ];

    # Inline all Lua configuration via builtins.readFile
    initLua = ''
      -- Core configuration
      ${builtins.readFile ./config/options.lua}
      ${builtins.readFile ./config/keymaps.lua}

      -- Plugin configurations (theme first)
      ${builtins.readFile ./config/plugins/catppuccin.lua}
      ${builtins.readFile ./config/plugins/telescope.lua}
      ${builtins.readFile ./config/plugins/lsp.lua}
      ${builtins.readFile ./config/plugins/luasnip.lua}
      ${builtins.readFile ./config/plugins/cmp.lua}
      ${builtins.readFile ./config/plugins/neo-tree.lua}
      ${builtins.readFile ./config/plugins/gitsigns.lua}
      ${builtins.readFile ./config/plugins/which-key.lua}
      ${builtins.readFile ./config/plugins/lualine.lua}
      ${builtins.readFile ./config/plugins/conform.lua}
      ${builtins.readFile ./config/plugins/toggleterm.lua}
      ${builtins.readFile ./config/plugins/indent-blankline.lua}
      ${builtins.readFile ./config/plugins/autopairs.lua}
      ${builtins.readFile ./config/plugins/comment.lua}
      ${builtins.readFile ./config/plugins/bufferline.lua}
      ${builtins.readFile ./config/plugins/treesitter.lua}
    '';
  };
}
