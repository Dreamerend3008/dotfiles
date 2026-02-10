-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              PLUGINS.LUA                                      ║
-- ║                                                                               ║
-- ║  Plugin definitions for lazy.nvim.                                           ║
-- ║                                                                               ║
-- ║  To add a plugin:                                                            ║
-- ║    1. Add it to the table below                                              ║
-- ║    2. Restart Neovim (or run :Lazy sync)                                     ║
-- ║                                                                               ║
-- ║  Plugin format:                                                              ║
-- ║    { "author/plugin-name" }                    -- Simple                     ║
-- ║    { "author/plugin", config = function() end } -- With configuration       ║
-- ║    { "author/plugin", dependencies = { ... } }  -- With dependencies        ║
-- ║                                                                               ║
-- ║  Docs: https://github.com/folke/lazy.nvim                                    ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

require("lazy").setup({
  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 🎨 COLORSCHEME                                                          │
  -- │                                                                          │
  -- │ GitHub's dark theme - clean and easy on the eyes                        │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  {
    "projekt0n/github-nvim-theme",
    lazy = false,           -- Load immediately (not lazily)
    priority = 1000,        -- Load before other plugins
    config = function()
      require("github-theme").setup({
        options = { style = "dark_default" },
      })
      vim.cmd("colorscheme github_dark_default")
    end,
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 🔧 LSP (Language Server Protocol)                                       │
  -- │                                                                          │
  -- │ Provides: code completion, go-to-definition, find references, etc.      │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  { "neovim/nvim-lspconfig" },  -- LSP configurations

  -- Mason - automatically install language servers
  { 
    "williamboman/mason.nvim", 
    build = ":MasonUpdate", 
    config = true 
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
  },

  -- LSP UI improvements (nicer popups for errors, definitions, etc.)
  {
    "nvimdev/lspsaga.nvim",
    config = function() 
      require("lspsaga").setup({}) 
    end,
    dependencies = { 
      "nvim-treesitter/nvim-treesitter", 
      "nvim-tree/nvim-web-devicons" 
    },
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 🔍 DIAGNOSTICS & FORMATTING                                             │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  
  -- Trouble - pretty list of diagnostics, references, etc.
  { 
    "folke/trouble.nvim", 
    dependencies = { "nvim-tree/nvim-web-devicons" }, 
    config = true 
  },

  -- Conform - code formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cpp    = { "clang-format" },  -- C++ formatting
        lua    = { "stylua" },        -- Lua formatting
        python = { "black" },         -- Python formatting
      },
    },
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ ✨ AUTOCOMPLETION                                                       │
  -- │                                                                          │
  -- │ nvim-cmp is the completion engine.                                      │
  -- │ The cmp-* plugins are "sources" - where completions come from.          │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",    -- Completions from LSP
      "hrsh7th/cmp-buffer",       -- Completions from current buffer
      "hrsh7th/cmp-path",         -- File path completions
      "L3MON4D3/LuaSnip",         -- Snippet engine
      "saadparwaiz1/cmp_luasnip", -- Snippet completions
    },
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 📝 EDITING ENHANCEMENTS                                                 │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  
  -- Auto-pairs - automatically close brackets, quotes, etc.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,  -- use treesitter to check for pairs
      })
    end,
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 🧭 NAVIGATION / UI                                                        │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "folke/which-key.nvim", event = "VeryLazy", config = true },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = true,
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = true,
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │  GIT                                                                     │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, config = true },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │  TERMINAL                                                                │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  { "akinsho/toggleterm.nvim", version = "*", cmd = { "ToggleTerm", "TermExec" }, config = true },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 🌳 TREESITTER                                                           │
  -- │                                                                          │
  -- │ Better syntax highlighting based on parsing, not regex.                 │
  -- │ Also enables smart indentation and text objects.                        │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("nvim-treesitter not available (run :Lazy sync and restart)", vim.log.levels.WARN)
        return
      end

      configs.setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "query", "nix", "bash",
          "c", "cpp", "python", "javascript", "typescript", "json", "markdown",
        },
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
})
