-- nvim-autopairs Configuration

local ok, autopairs = pcall(require, "nvim-autopairs")
if not ok then return end

autopairs.setup({
  check_ts = true, -- Use treesitter for smarter pairing
  ts_config = {
    lua = { "string" },
    javascript = { "template_string" },
  },
  fast_wrap = {
    map = "<M-e>",
  },
})

-- Integration with nvim-cmp: auto-insert pairs after function completion
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end
