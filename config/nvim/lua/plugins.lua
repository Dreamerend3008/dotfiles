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

  -- Undotree - visualize and navigate undo history
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Toggle undo tree" } },
  },

  -- ╭─────────────────────────────────────────────────────────────────────────╮
  -- │ 🧭 NAVIGATION / UI                                                        │
  -- ╰─────────────────────────────────────────────────────────────────────────╯
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({})
      -- Support for both which-key v3 (wk.add) and v2 (wk.register)
      if wk.add then
        wk.add({
          { "<leader>n", group = "Notes / Obsidian" },
        })
      elseif wk.register then
        wk.register({
          n = { name = "Notes / Obsidian" }
        }, { prefix = "<leader>" })
      end
    end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      image = {
        enabled = true,
        resolve = function(file, src)
          -- Let snacks handle absolute paths or web URLs directly.
          if src:match("^https?://") or src:match("^/") then
            return nil
          end

          -- Prefer obsidian.nvim's attachment resolver for vault notes.
          local ok, api = pcall(require, "obsidian.api")
          if ok and api.path_is_note(file) then
            local attachment_path = api.resolve_attachment_path(src)
            if attachment_path ~= nil then
              return tostring(attachment_path)
            end
          end

          -- Fallback for plain markdown files outside an Obsidian vault.
          local file_dir = vim.fs.dirname(file)
          local candidates = {
            file_dir .. "/" .. src,
            file_dir .. "/attachments/" .. src,
            file_dir .. "/images/" .. src,
            file_dir .. "/assets/" .. src,
            vim.fn.expand("~/Notes/" .. src),
            vim.fn.expand("~/Notes/attachments/" .. src),
            vim.fn.expand("~/Notes/images/" .. src),
            vim.fn.expand("~/Notes/assets/" .. src),
            vim.fn.expand("~/vaults/work/" .. src),
            vim.fn.expand("~/vaults/work/attachments/" .. src),
          }

          for _, path in ipairs(candidates) do
            if vim.fn.filereadable(path) == 1 then
              return path
            end
          end
          return nil
        end,
      },
    },
  },
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
    branch = "main",
    build = ":TSUpdate",
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter")
      if not ok then
        return
      end

      ts.setup({})

      -- Install parsers asynchronously
      ts.install({
        "lua", "vim", "vimdoc", "query", "nix", "bash",
        "c", "cpp", "python", "javascript", "typescript", "json", "markdown",
      })

      -- Enable Treesitter highlight & indent via autocommands
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim-treesitter-setup", { clear = true }),
        callback = function(args)
          -- Start built-in treesitter highlighting
          pcall(vim.treesitter.start)

          -- Indentation (ignoring cpp and c as in user's config)
          local ft = vim.bo[args.buf].filetype
          if ft ~= "cpp" and ft ~= "c" then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

-- Obsidian plugin

{
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    cmd = { "Obsidian" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "harry-notes",
          path = "~/Notes/",
        },
      },
      note_id_func = function(title)
        if title ~= nil then
          return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-_]", ""):lower()
        else
          local suffix = ""
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
          return tostring(os.time()) .. "-" .. suffix
        end
      end,
      link = {
        style = "wiki",
      },
      attachments = {
        folder = "attachments",
        img_name_func = function()
          return string.format("pasted-image-%s", os.date("%Y%m%d-%H%M%S"))
        end,
        confirm_img_paste = true,
      },
    },
  },
})

