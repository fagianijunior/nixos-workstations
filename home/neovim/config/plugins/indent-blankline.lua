-- indent-blankline v3 (ibl) Configuration

local ok, ibl = pcall(require, "ibl")
if not ok then return end

ibl.setup({
  indent = {
    char = "│",
    tab_char = "│",
  },
  scope = {
    enabled = true,
    show_start = true,
    show_end = false,
  },
  exclude = {
    filetypes = {
      "help",
      "neo-tree",
      "lazy",
      "mason",
      "toggleterm",
      "dashboard",
    },
  },
})
