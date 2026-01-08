-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              NEOVIM INIT.LUA                                  ║
-- ║                                                                               ║
-- ║  Entry point for Neovim configuration.                                       ║
-- ║  This file bootstraps lazy.nvim and loads all modules.                       ║
-- ║                                                                               ║
-- ║  Structure:                                                                   ║
-- ║    init.lua      - This file (entry point)                                   ║
-- ║    lua/                                                                       ║
-- ║      options.lua - Basic vim options (line numbers, tabs, etc.)              ║
-- ║      keymaps.lua - Custom keybindings                                        ║
-- ║      plugins.lua - Plugin list (managed by lazy.nvim)                        ║
-- ║      lsp.lua     - Language Server Protocol configuration                    ║
-- ║      completion.lua - Autocompletion setup                                   ║
-- ║      cp.lua      - Competitive programming helpers                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Bootstrap lazy.nvim (plugin manager)                                        │
-- │                                                                             │
-- │ This automatically installs lazy.nvim if it's not already installed.       │
-- │ lazy.nvim is the modern replacement for packer, vim-plug, etc.             │
-- └────────────────────────────────────────────────────────────────────────────┘
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Load configuration modules                                                  │
-- │                                                                             │
-- │ Each require() loads a file from the lua/ directory.                       │
-- │ Order matters! Options and keymaps should load before plugins.             │
-- └────────────────────────────────────────────────────────────────────────────┘
require("options")      -- Basic vim settings
require("keymaps")      -- Custom keybindings
require("plugins")      -- Plugin definitions (lazy.nvim)
require("lsp")          -- Language Server Protocol
require("completion")   -- Autocompletion
require("cp")           -- Competitive programming helpers
