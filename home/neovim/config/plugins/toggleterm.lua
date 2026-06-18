-- Toggleterm Configuration

local ok, toggleterm = pcall(require, "toggleterm")
if not ok then return end

toggleterm.setup({
  size = function(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,
  open_mapping = [[<C-\>]],
  direction = "float",
  shell = "fish",
  float_opts = {
    border = "curved",
    winblend = 3,
  },
})

-- Numbered terminal keybindings
local Terminal = require("toggleterm.terminal").Terminal

for i = 1, 4 do
  vim.keymap.set("n", "<leader>t" .. i, function()
    Terminal:new({ id = i, direction = "float" }):toggle()
  end, { desc = "Terminal " .. i })
end
