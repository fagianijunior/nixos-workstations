-- Treesitter Configuration

local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then return end

treesitter.setup({
  -- Parsers managed by Nix — no runtime install
  auto_install = false,

  highlight = {
    enable = true,
    -- Disable for very large files
    disable = function(_, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local stat_ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if stat_ok and stats and stats.size > max_filesize then
        return true
      end
    end,
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,
    disable = { "python" },
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = "<C-s>",
      node_decremental = "<C-backspace>",
    },
  },

  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
    swap = {
      enable = true,
      swap_next = { ["<leader>a"] = "@parameter.inner" },
      swap_previous = { ["<leader>A"] = "@parameter.inner" },
    },
  },
})

-- Folding via treesitter (disabled by default)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false

-- Associate .tfvars with terraform filetype
vim.filetype.add({
  extension = { tfvars = "terraform" },
  pattern = { [".*%.tfvars"] = "terraform" },
})
