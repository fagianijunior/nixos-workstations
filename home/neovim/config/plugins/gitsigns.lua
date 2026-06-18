-- Gitsigns Configuration

local ok, gitsigns = pcall(require, "gitsigns")
if not ok then return end

gitsigns.setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },

  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local opts = { buffer = bufnr }

    -- Navigation
    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then return "]c" end
      vim.schedule(function() gs.next_hunk() end)
      return "<Ignore>"
    end, vim.tbl_extend("force", opts, { expr = true, desc = "Next hunk" }))

    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then return "[c" end
      vim.schedule(function() gs.prev_hunk() end)
      return "<Ignore>"
    end, vim.tbl_extend("force", opts, { expr = true, desc = "Previous hunk" }))

    -- Actions
    vim.keymap.set("n", "<leader>hs", gs.stage_hunk, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
    vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, vim.tbl_extend("force", opts, { desc = "Undo stage hunk" }))
    vim.keymap.set("n", "<leader>hr", gs.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
    vim.keymap.set("n", "<leader>hS", gs.stage_buffer, vim.tbl_extend("force", opts, { desc = "Stage buffer" }))
    vim.keymap.set("n", "<leader>hR", gs.reset_buffer, vim.tbl_extend("force", opts, { desc = "Reset buffer" }))
    vim.keymap.set("n", "<leader>hb", function() gs.blame_line({ full = true }) end, vim.tbl_extend("force", opts, { desc = "Blame line" }))
    vim.keymap.set("n", "<leader>hp", gs.preview_hunk, vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
    vim.keymap.set("n", "<leader>hd", gs.diffthis, vim.tbl_extend("force", opts, { desc = "Diff this" }))
    vim.keymap.set("n", "<leader>hD", function() gs.diffthis("~") end, vim.tbl_extend("force", opts, { desc = "Diff this ~" }))

    -- Toggles
    vim.keymap.set("n", "<leader>tb", gs.toggle_current_line_blame, vim.tbl_extend("force", opts, { desc = "Toggle line blame" }))
    vim.keymap.set("n", "<leader>td", gs.toggle_deleted, vim.tbl_extend("force", opts, { desc = "Toggle deleted" }))

    -- Visual mode stage/reset
    vim.keymap.set("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
    vim.keymap.set("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
  end,
})
