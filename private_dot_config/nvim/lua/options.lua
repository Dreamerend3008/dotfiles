-- basic options
vim.opt.splitright    = true
vim.opt.splitbelow    = true
vim.g.mapleader       = " "
vim.g.maplocalleader  = " "
vim.opt.termguicolors = true
vim.opt.pumheight     = 2   -- limit completion menu height

-- transparent popup menu
vim.cmd("highlight Pmenu guibg=NONE ctermbg=NONE")
vim.cmd("highlight PmenuSel guibg=Grey guifg=Black")

