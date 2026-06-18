# Code Generation Plan — Neovim Integration

## Unit Context

- **Unit Name**: neovim-integration (single unit)
- **Project Type**: Brownfield (adding module to existing NixOS flake)
- **Target**: `/home/terabytes/Workspace/fagianijunior/nixos/home/neovim/`
- **Channel**: nixos-unstable
- **Integration Point**: `home/default.nix` (add import)
- **Reference**: `to_implement/neovim/` (outdated, for structure reference only)

## Dependencies
- nixpkgs (nixos-unstable) — plugins via vimPlugins, LSPs via pkgs
- Home Manager — programs.neovim module
- Catppuccin — autoEnable already configured in home/default.nix

## Verified Package Names (nixpkgs unstable)

### Vim Plugins
- `vimPlugins.catppuccin-nvim`
- `vimPlugins.telescope-nvim`, `vimPlugins.plenary-nvim`, `vimPlugins.telescope-fzf-native-nvim`
- `vimPlugins.nvim-lspconfig`
- `vimPlugins.nvim-cmp`, `vimPlugins.cmp-nvim-lsp`, `vimPlugins.cmp-buffer`, `vimPlugins.cmp-path`, `vimPlugins.cmp_luasnip`, `vimPlugins.cmp-cmdline`
- `vimPlugins.luasnip`, `vimPlugins.friendly-snippets`
- `vimPlugins.nvim-treesitter` (with `.withPlugins`)
- `vimPlugins.nvim-treesitter-textobjects`
- `vimPlugins.gitsigns-nvim`
- `vimPlugins.neo-tree-nvim`, `vimPlugins.nvim-web-devicons`, `vimPlugins.nui-nvim`
- `vimPlugins.which-key-nvim`
- `vimPlugins.lualine-nvim`
- `vimPlugins.conform-nvim`
- `vimPlugins.toggleterm-nvim`
- `vimPlugins.indent-blankline-nvim` (v3.9.1)
- `vimPlugins.nvim-autopairs` (v0.10.0)
- `vimPlugins.comment-nvim` (v0.8.0)
- `vimPlugins.bufferline-nvim` (v4.9.1)

### LSPs & Tools (extraPackages)
- `pkgs.nixd` — Nix LSP
- `pkgs.terraform-ls` — Terraform LSP (already in home.packages, keep in extraPackages for encapsulation)
- `pkgs.rubyPackages.solargraph` — Ruby LSP
- `pkgs.intelephense` — PHP LSP (unfree)
- `pkgs.pyright` — Python LSP
- `pkgs.lua-language-server` — Lua LSP
- `pkgs.bash-language-server` — Bash LSP
- `pkgs.dockerfile-language-server` — Dockerfile LSP

### Formatters (extraPackages)
- `pkgs.nixpkgs-fmt` — Nix formatter
- `pkgs.nodePackages.prettier` — JSON/YAML/MD/HTML/CSS
- `pkgs.stylua` — Lua formatter
- `pkgs.rubocop` — Ruby formatter
- `pkgs.phpPackages.php-cs-fixer` — PHP formatter (php84Packages)
- `pkgs.black` — Python formatter
- `pkgs.shfmt` — Shell formatter
- `pkgs.terraform` — terraform fmt (built-in subcommand)

### Telescope Dependencies (extraPackages)
- `pkgs.ripgrep`
- `pkgs.fd`

## Code Generation Steps

---

### Step 1: Create Directory Structure
- [x] Create `home/neovim/` directory
- [x] Create `home/neovim/config/` directory
- [x] Create `home/neovim/config/plugins/` directory

---

### Step 2: Create Nix Module — `home/neovim/default.nix`
- [x] Create the main Nix module with:
  - `programs.neovim` configuration (enable, aliases, defaultEditor)
  - `plugins` list with all 20 plugins (16 base + 4 new)
  - `nvim-treesitter.withPlugins` with all 25 parsers
  - `extraPackages` with all LSPs, formatters, and tools
  - `initLua` using `builtins.readFile` for all config files
  - Proper ordering of Lua file loading

---

### Step 3: Create Core Config — `home/neovim/config/options.lua`
- [x] Neovim options: line numbers, indentation, search, appearance, behavior, splits, performance, scrolling, command-line completion
- [x] Based on reference with same settings

---

### Step 4: Create Core Config — `home/neovim/config/keymaps.lua`
- [x] Leader key setup (Space)
- [x] Window navigation (C-h/j/k/l)
- [x] Window resize (C-Up/Down/Left/Right)
- [x] Buffer navigation (S-h/S-l)
- [x] Better indenting (visual mode)
- [x] Move text (visual mode)
- [x] Centered scrolling (C-d/C-u)
- [x] Centered search (n/N)
- [x] Clear search highlighting (Esc)
- [x] Better paste (x mode)
- [x] Save (C-s), Quit (leader-q/Q)

---

### Step 5: Create Plugin Config — `home/neovim/config/plugins/catppuccin.lua`
- [x] Catppuccin setup with overrides for integrations
- [x] Enable integrations: telescope, cmp, treesitter, gitsigns, neo-tree, indent-blankline, bufferline, which-key
- [x] Flavor: macchiato (override for explicit control)

---

### Step 6: Create Plugin Config — `home/neovim/config/plugins/telescope.lua`
- [x] Telescope setup with FZF native extension
- [x] Keybindings: leader-ff, leader-fg, leader-fb, leader-fc, leader-fh, leader-fk, leader-fr, leader-fw, leader-fd

---

### Step 7: Create Plugin Config — `home/neovim/config/plugins/lsp.lua`
- [x] Diagnostic configuration (virtual_text, signs, float)
- [x] Diagnostic signs (Nerd Font icons)
- [x] on_attach function with LSP keybindings (gd, K, gr, leader-rn, leader-ca, gD, gi, etc.)
- [x] Capabilities integration with nvim-cmp
- [x] Configure 8 LSP servers:
  - lua_ls (with Neovim API diagnostics)
  - nixd (with nixpkgs-fmt formatting)
  - terraform-ls (terraform-ls — nome correto do server)
  - solargraph (Ruby)
  - intelephense (PHP)
  - pyright (Python)
  - bashls (Bash)
  - dockerls (Dockerfile)
- [x] NO format-on-save in LSP (delegated to conform.nvim to avoid conflicts)

---

### Step 8: Create Plugin Config — `home/neovim/config/plugins/luasnip.lua`
- [x] LuaSnip setup
- [x] Load friendly-snippets (VSCode-style snippets)
- [x] Snippet navigation keybindings

---

### Step 9: Create Plugin Config — `home/neovim/config/plugins/cmp.lua`
- [x] nvim-cmp setup with snippet engine (luasnip)
- [x] Bordered windows
- [x] Keybindings: Tab, S-Tab, CR, C-Space, C-b, C-f, C-e
- [x] Sources: nvim_lsp > luasnip > buffer > path
- [x] Formatting with source labels
- [x] Ghost text enabled
- [x] Cmdline completion (: and /)

---

### Step 10: Create Plugin Config — `home/neovim/config/plugins/treesitter.lua`
- [x] Treesitter setup (auto_install = false, Nix-managed)
- [x] Highlight module (with large file disable)
- [x] Indent module (disable for Python)
- [x] Incremental selection (C-space, C-backspace)
- [x] Text objects (function, class, parameter)
- [x] Text objects movement (]m, [m, ]], [[)
- [x] Text objects swap (leader-a, leader-A)
- [x] Folding (foldmethod=expr, disabled by default)
- [x] .tfvars filetype association

---

### Step 11: Create Plugin Config — `home/neovim/config/plugins/gitsigns.lua`
- [x] Gitsigns setup
- [x] on_attach with keybindings: leader-hs/hu/hr/hS/hR/hb/hp/hd/hD, ]c/[c
- [x] Toggle keybindings: leader-tb (blame), leader-td (deleted)

---

### Step 12: Create Plugin Config — `home/neovim/config/plugins/neo-tree.lua`
- [x] Neo-tree setup
- [x] Filesystem source with follow_current_file
- [x] Git status integration
- [x] Keybinding: leader-e (toggle)

---

### Step 13: Create Plugin Config — `home/neovim/config/plugins/which-key.lua`
- [x] Which-key setup
- [x] Group registrations for leader prefixes (f=Find, h=Git Hunks, c=Code, r=Refactor, d=Diagnostics, w=Workspace, t=Terminal, e=Explorer, q=Quit)

---

### Step 14: Create Plugin Config — `home/neovim/config/plugins/lualine.lua`
- [x] Lualine setup with catppuccin theme
- [x] Sections: mode, branch, diff, diagnostics, filename, encoding, filetype, progress, location

---

### Step 15: Create Plugin Config — `home/neovim/config/plugins/conform.lua`
- [x] Conform setup with formatters_by_ft:
  - nix → nixpkgs_fmt
  - terraform → terraform_fmt
  - json/yaml/markdown/html/css/scss → prettier
  - lua → stylua
  - ruby → rubocop
  - php → php_cs_fixer
  - python → black
  - sh/bash → shfmt
- [x] format_on_save (timeout 500ms, lsp_fallback)
- [x] Manual format keybinding: leader-cf

---

### Step 16: Create Plugin Config — `home/neovim/config/plugins/toggleterm.lua`
- [x] Toggleterm setup (direction=float, shell=fish)
- [x] Keybindings: leader-t1/t2/t3/t4 (numbered terminals)
- [x] C-\ toggle

---

### Step 17: Create Plugin Config — `home/neovim/config/plugins/indent-blankline.lua`
- [x] indent-blankline v3 (ibl) setup
- [x] Scope highlighting enabled
- [x] Catppuccin integration (colors via highlight groups)

---

### Step 18: Create Plugin Config — `home/neovim/config/plugins/autopairs.lua`
- [x] nvim-autopairs setup
- [x] Integration with nvim-cmp (auto-insert pairs after function completion)
- [x] Disable in certain filetypes if needed

---

### Step 19: Create Plugin Config — `home/neovim/config/plugins/comment.lua`
- [x] Comment.nvim setup
- [x] Default keybindings: gcc (line), gc (visual block)
- [x] Treesitter integration for context-aware comments

---

### Step 20: Create Plugin Config — `home/neovim/config/plugins/bufferline.lua`
- [x] Bufferline setup
- [x] Catppuccin highlights integration
- [x] Show buffer close button
- [x] Diagnostics indicator from LSP

---

### Step 21: Integrate with Home Manager — Update `home/default.nix`
- [x] Add `./neovim` to imports list
- [x] Remove redundant packages from `home.packages` that are now in neovim extraPackages:
  - Remove `nil` (replaced by nixd in extraPackages)
  - Remove `nixpkgs-fmt` (in extraPackages)
  - Remove `terraform-ls` (in extraPackages)
  - Remove `rubyPackages.solargraph` (in extraPackages)
  - Keep `nixd` in home.packages (used by other tools like Kiro MCP)

---

### Step 22: Create Test — `tests/neovim-test.nix`
- [x] runNixOSTest with:
  - Neovim starts without errors (`nvim --headless -c 'qall'`)
  - Colorscheme is catppuccin (`nvim --headless -c 'echo g:colors_name' -c 'qall'`)
  - All LSPs are available in PATH (nixd, terraform-ls, solargraph, intelephense, pyright, lua-language-server, bash-language-server, dockerfile-language-server)
  - All formatters are available in PATH (nixpkgs-fmt, prettier, stylua, rubocop, php-cs-fixer, black, shfmt)
  - Treesitter parsers are installed (check runtime path)
  - Plugins load without errors (`nvim --headless -c 'lua require("telescope")' -c 'qall'`)
  - LSP healthcheck passes (`nvim --headless -c 'checkhealth lspconfig' -c 'qall'`)

---

### Step 23: Update Flake — Add test to checks
- [x] Add neovim-test to `checks.x86_64-linux` in flake.nix (if not auto-discovered)
- [x] Verify `nix flake check` passes

---

## Summary

| Category | Files | Count |
|----------|-------|-------|
| Nix module | home/neovim/default.nix | 1 |
| Core Lua configs | home/neovim/config/{options,keymaps}.lua | 2 |
| Plugin Lua configs | home/neovim/config/plugins/*.lua | 16 |
| Integration | home/default.nix (modify) | 1 |
| Tests | tests/neovim-test.nix | 1 |
| Flake | flake.nix (modify if needed) | 1 |
| **Total** | | **~22 files (19 new + 3 modified)** |

## Extension Compliance Notes

### Security Baseline
- SECURITY-10: All packages pinned via flake.lock ✓
- SECURITY-12: No hardcoded credentials ✓
- SECURITY-13: Nix store integrity (all plugins/LSPs from nixpkgs) ✓
- Note: `intelephense` is unfree — requires `nixpkgs.config.allowUnfree = true` or per-package allowance

### PBT (Partial)
- PBT-02: Round-trip — module produces valid Neovim config (tested via headless start) ✓
- PBT-03: Invariants — all configured LSPs/formatters available (tested in PATH) ✓
- PBT-08: Reproducibility — deterministic test (same VM, same config) ✓
- PBT-09: Framework — runNixOSTest ✓
