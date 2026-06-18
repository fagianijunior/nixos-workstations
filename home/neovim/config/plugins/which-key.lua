-- Which-key Configuration

local ok, wk = pcall(require, "which-key")
if not ok then return end

wk.setup({
  plugins = {
    spelling = { enabled = true, suggestions = 20 },
  },
  win = {
    border = "rounded",
  },
})

-- Register group prefixes
wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>h", group = "Git Hunks" },
  { "<leader>c", group = "Code" },
  { "<leader>r", group = "Refactor" },
  { "<leader>d", group = "Diagnostics" },
  { "<leader>w", group = "Workspace" },
  { "<leader>t", group = "Terminal/Toggle" },
})
