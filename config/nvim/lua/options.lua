-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              OPTIONS.LUA                                      ║
-- ║                                                                               ║
-- ║  Basic Neovim settings - how the editor looks and behaves.                   ║
-- ║                                                                               ║
-- ║  vim.opt.X = Y   →  Same as :set X=Y in vimscript                            ║
-- ║  vim.g.X = Y     →  Same as :let g:X = Y (global variables)                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Leader Key                                                                  │
-- │                                                                             │
-- │ The leader key is a prefix for custom shortcuts.                           │
-- │ <leader>w means: press Space, then w                                       │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.g.mapleader = " "           -- Space as leader key
vim.g.maplocalleader = " "      -- Space as local leader too

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Appearance                                                                  │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Relative line numbers (useful for jumps)
vim.opt.cursorline = true       -- Highlight current line
vim.opt.signcolumn = "yes"      -- Always show sign column (for git, diagnostics)
vim.opt.pumheight = 10          -- Max items in completion popup

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Indentation                                                                 │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.opt.tabstop = 4             -- Tab = 4 spaces visually
vim.opt.shiftwidth = 4          -- Indent by 4 spaces
vim.opt.softtabstop = 4         -- Tab key inserts 4 spaces
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.smartindent = true      -- Auto-indent new lines

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Search                                                                      │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.opt.ignorecase = true       -- Ignore case when searching
vim.opt.smartcase = true        -- Unless search has uppercase
vim.opt.hlsearch = true         -- Highlight search results
vim.opt.incsearch = true        -- Show matches as you type

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Splits                                                                      │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.opt.splitright = true       -- New vertical splits go right
vim.opt.splitbelow = true       -- New horizontal splits go below

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Behavior                                                                    │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.opt.mouse = "a"             -- Enable mouse support
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.undofile = true         -- Persistent undo (survives closing file)
vim.opt.swapfile = false        -- No swap files (annoying)
vim.opt.updatetime = 250        -- Faster completion (ms)
vim.opt.timeoutlen = 300        -- Faster key sequence completion

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Transparent popup menu (for completion)                                     │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.cmd("highlight Pmenu guibg=NONE ctermbg=NONE")
vim.cmd("highlight PmenuSel guibg=Grey guifg=Black")
