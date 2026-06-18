-- conform.nvim — Code Formatting

local ok, conform = pcall(require, "conform")
if not ok then return end

conform.setup({
  formatters_by_ft = {
    -- Nix
    nix = { "nixpkgs_fmt" },

    -- Terraform / HCL
    terraform = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },

    -- Web / Data formats
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    markdown = { "prettier" },

    -- Lua
    lua = { "stylua" },

    -- Ruby
    ruby = { "rubocop" },

    -- PHP
    php = { "php_cs_fixer" },

    -- Python
    python = { "black" },

    -- Shell
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})

-- Manual format keybinding
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format({
    lsp_fallback = true,
    async = false,
    timeout_ms = 500,
  })
end, { desc = "Format file or range" })
