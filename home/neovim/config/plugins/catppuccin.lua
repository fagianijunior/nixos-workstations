-- Catppuccin Theme Configuration
-- autoEnable from Home Manager handles the base theme.
-- This provides explicit integration overrides for plugin highlights.

local ok, catppuccin = pcall(require, "catppuccin")
if not ok then return end

catppuccin.setup({
  flavour = "macchiato",
  transparent_background = false,
  term_colors = true,
  integrations = {
    cmp = true,
    gitsigns = true,
    telescope = { enabled = true },
    treesitter = true,
    neo_tree = true,
    indent_blankline = { enabled = true, scope_color = "lavender" },
    which_key = true,
    bufferline = true,
    native_lsp = {
      enabled = true,
      underlines = {
        errors = { "undercurl" },
        hints = { "undercurl" },
        warnings = { "undercurl" },
        information = { "undercurl" },
      },
    },
  },
})

vim.cmd.colorscheme("catppuccin")
