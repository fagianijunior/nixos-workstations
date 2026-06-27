-- Neo-tree Configuration

local ok, neo_tree = pcall(require, "neo-tree")
if not ok then return end

neo_tree.setup({
  close_if_last_window = true,
  enable_git_status = true,
  enable_normal_mode_for_inputs = false,
  enable_diagnostics = true,
  popup_border_style = "rounded",
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = false,
      hide_by_name = { ".git", "node_modules", ".cache" },
    },
  },
  window = {
    width = 35,
    mappings = {
      ["<space>"] = "none",
    },
  },
  default_component_configs = {
    git_status = {
      symbols = {
        added = "",
        modified = "",
        deleted = "✖",
        renamed = "󰁕",
        untracked = "",
        ignored = "",
        unstaged = "󰄱",
        staged = "",
        conflict = "",
      },
    },
  },
})

vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
