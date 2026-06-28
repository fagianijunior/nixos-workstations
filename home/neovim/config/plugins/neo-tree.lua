-- Neo-tree Configuration

local ok, neo_tree = pcall(require, "neo-tree")
if not ok then return end

neo_tree.setup({
  close_if_last_window = false,
  popup_border_style = "rounded",
  sources = { "filesystem", "buffers", "git_status" },
  source_selector = {
    winbar = false,
  },
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

-- When neo-tree is the only window left, switch to a hidden buffer or quit
vim.api.nvim_create_autocmd("WinClosed", {
  group = vim.api.nvim_create_augroup("NeoTreeAutoClose", { clear = true }),
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_list_wins()
      -- Check if all remaining windows are neo-tree
      local only_neotree = true
      local neotree_win = nil
      for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft ~= "neo-tree" then
            only_neotree = false
            break
          else
            neotree_win = win
          end
        end
      end
      if not only_neotree then return end

      -- Check for hidden listed buffers to switch to
      local next_buf = nil
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "neo-tree" then
          next_buf = buf
          break
        end
      end

      if next_buf then
        -- Open a new window to the right of neo-tree with the buffer
        vim.cmd("botright vsplit")
        vim.cmd("b " .. next_buf)
        -- Resize neo-tree back to its configured width
        if neotree_win and vim.api.nvim_win_is_valid(neotree_win) then
          vim.api.nvim_win_set_width(neotree_win, 35)
        end
      else
        vim.cmd("qa!")
      end
    end)
  end,
})
