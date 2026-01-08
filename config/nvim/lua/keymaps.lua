-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              KEYMAPS.LUA                                      ║
-- ║                                                                               ║
-- ║  Custom keybindings for Neovim.                                              ║
-- ║                                                                               ║
-- ║  Format: vim.keymap.set(mode, key, action, options)                          ║
-- ║    mode: "n" = normal, "i" = insert, "v" = visual, "x" = visual block        ║
-- ║    key: the key combination (e.g., "<leader>w" = Space+w)                    ║
-- ║    action: command to run or function                                        ║
-- ║    options: { desc = "description" } for which-key                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ General Keymaps                                                             │
-- └────────────────────────────────────────────────────────────────────────────┘

-- Save file with Ctrl+S (works in normal and insert mode)
keymap("n", "<C-s>", ":w<CR>", { desc = "Save file" })
keymap("i", "<C-s>", "<Esc>:w<CR>a", { desc = "Save file" })

-- Quit with leader+q
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Clear search highlight with Escape
keymap("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Window Navigation                                                           │
-- │                                                                             │
-- │ Use Ctrl+h/j/k/l to move between splits                                    │
-- └────────────────────────────────────────────────────────────────────────────┘
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Buffer Navigation                                                           │
-- └────────────────────────────────────────────────────────────────────────────┘
keymap("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
keymap("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<leader>x", ":bdelete<CR>", { desc = "Close buffer" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Line Movement                                                               │
-- │                                                                             │
-- │ Move selected lines up/down with Alt+j/k                                   │
-- └────────────────────────────────────────────────────────────────────────────┘
keymap("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
keymap("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Indentation (stay in visual mode)                                           │
-- └────────────────────────────────────────────────────────────────────────────┘
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Diagnostic Keymaps (for LSP errors/warnings)                                │
-- └────────────────────────────────────────────────────────────────────────────┘
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
keymap("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
