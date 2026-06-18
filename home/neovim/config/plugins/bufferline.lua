-- Bufferline Configuration

local ok, bufferline = pcall(require, "bufferline")
if not ok then return end

bufferline.setup({
  options = {
    mode = "buffers",
    themable = true,
    close_command = "bdelete! %d",
    right_mouse_command = "bdelete! %d",
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(count, level)
      local icon = level:match("error") and " " or " "
      return " " .. icon .. count
    end,
    offsets = {
      {
        filetype = "neo-tree",
        text = "File Explorer",
        highlight = "Directory",
        separator = true,
      },
    },
    show_buffer_close_icons = true,
    show_close_icon = false,
    separator_style = "thin",
  },
  highlights = require("catppuccin.groups.integrations.bufferline").get(),
})
