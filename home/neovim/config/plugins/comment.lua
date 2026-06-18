-- Comment.nvim Configuration

local ok, comment = pcall(require, "Comment")
if not ok then return end

comment.setup({
  -- gcc: toggle line comment
  -- gc: toggle comment in visual mode
  -- gcb: toggle block comment
  toggler = {
    line = "gcc",
    block = "gbc",
  },
  opleader = {
    line = "gc",
    block = "gb",
  },
  -- Use treesitter for context-aware comments (e.g., JSX)
  pre_hook = function(ctx)
    local ok_ts, ts_comment = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
    if ok_ts then
      return ts_comment.create_pre_hook()(ctx)
    end
  end,
})
