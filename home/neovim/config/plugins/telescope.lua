-- Telescope Configuration

local ok, telescope = pcall(require, "telescope")
if not ok then return end

telescope.setup({
  defaults = {
    prompt_prefix = "   ",
    selection_caret = " ",
    path_display = { "truncate" },
    sorting_strategy = "ascending",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
      },
      width = 0.87,
      height = 0.80,
    },
  },
  pickers = {
    find_files = { hidden = true },
    live_grep = { additional_args = { "--hidden" } },
  },
})

-- Load FZF native extension for better sorting
pcall(telescope.load_extension, "fzf")

-- Keybindings
local builtin = require("telescope.builtin")
local keymap = vim.keymap.set

keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
keymap("n", "<leader>fc", builtin.commands, { desc = "Find commands" })
keymap("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
keymap("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
keymap("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files" })
keymap("n", "<leader>fw", builtin.grep_string, { desc = "Find word under cursor" })
keymap("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostics" })
