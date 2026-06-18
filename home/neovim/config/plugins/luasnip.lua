-- LuaSnip Configuration

local ok, luasnip = pcall(require, "luasnip")
if not ok then return end

luasnip.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
})

-- Load VSCode-style snippets from friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()
