# Neovim Navigation Guide (your config)

This guide is based on your config in `config/nvim/`.

## 1) Where things are (so you can navigate the config itself)

Entry point:
- `config/nvim/init.lua` loads modules in this order:
  1. `lua/options.lua` (UI + behavior, **leader key**)
  2. `lua/keymaps.lua` (general navigation shortcuts)
  3. `lua/plugins.lua` (plugins via **lazy.nvim**)
  4. `lua/lsp.lua` (LSP + LSP-only keymaps)
  5. `lua/completion.lua` (nvim-cmp completion)
  6. `lua/cp.lua` (competitive programming helpers)

If you want to change…
- **Leader key / line numbers / splits / clipboard / tabs** → `lua/options.lua`
- **Most custom navigation keys** → `lua/keymaps.lua`
- **Add/remove plugins** → `lua/plugins.lua`
- **Go-to-definition, hover, rename, formatting** → `lua/lsp.lua`
- **Completion menu keys** → `lua/completion.lua`
- **CP workflow (input/expected/run/diff)** → `lua/cp.lua`

---

## 2) The one concept: your leader key

Your leader is **Space**:
- `<leader>x` means: press **Space**, then `x`.

You also have **which-key** installed, so after pressing **Space** and pausing briefly, you should see a popup of available leader mappings.

---

## 3) Moving around windows (splits)

You have IDE-style split navigation:

| Action | Key |
|---|---|
| Move to left split | `<C-h>` |
| Move to down split | `<C-j>` |
| Move to up split | `<C-k>` |
| Move to right split | `<C-l>` |

Notes:
- These are pure window focus moves (`<C-w>h/j/k/l`).
- Your `options.lua` sets `splitright=true` and `splitbelow=true` (new splits open right/below).

---

## 4) Moving around files (buffers)

Buffers are “open files” in Neovim.

| Action | Key |
|---|---|
| Next buffer | `<Tab>` |
| Previous buffer | `<S-Tab>` |
| Close (delete) buffer | `<leader>x` |

---

## 5) Fast file navigation (Telescope)

These open Telescope pickers:

| Action | Key |
|---|---|
| Find files | `<leader>ff` |
| Search text (live grep) | `<leader>fg` |
| Switch buffers | `<leader>fb` |
| Search help | `<leader>fh` |

Typical Telescope flow:
1. Trigger picker (e.g. `<leader>ff`).
2. Type to filter.
3. Press `<CR>` to open the selection.

---

## 6) File explorer (Oil)

| Action | Key |
|---|---|
| Open file explorer | `<leader>o` |

Oil opens a directory buffer you can edit/navigate to move/rename/create files.

---

## 7) Terminal toggling

| Action | Key |
|---|---|
| Toggle terminal | `<leader>tt` |

This uses **toggleterm.nvim**.

---

## 8) Search + “get unstuck”

| Action | Key |
|---|---|
| Clear search highlighting | `<Esc>` |

(This maps `<Esc>` in normal mode to `:nohlsearch`.)

---

## 9) Diagnostics navigation (errors/warnings)

Works with LSP diagnostics:

| Action | Key |
|---|---|
| Previous diagnostic | `[d` |
| Next diagnostic | `]d` |
| Show diagnostic float | `<leader>e` |

You also have **trouble.nvim** installed, which can show diagnostics in a list (run `:Trouble` / `:TroubleToggle` depending on version).

---

## 10) LSP “code navigation” (when a language server is attached)

These are set in `lua/lsp.lua` inside an `LspAttach` autocmd, so they only activate when an LSP server is running for the buffer.

| Action | Key |
|---|---|
| Go to definition | `gd` |
| Go to declaration | `gD` |
| Hover docs | `K` |
| Go to implementation | `gi` |
| Find references | `gr` |
| Rename symbol | `<leader>rn` |
| Code action | `<leader>ca` |
| Format buffer | `<leader>f` |

---

## 11) Editing moves you added (nice quality-of-life)

Move lines / selections:

| Action | Key |
|---|---|
| Move current line down | `<A-j>` |
| Move current line up | `<A-k>` |
| Move selection down (visual) | `<A-j>` |
| Move selection up (visual) | `<A-k>` |

Indent while staying in visual mode:

| Action | Key |
|---|---|
| Indent left | `<` (visual) |
| Indent right | `>` (visual) |

Save / Quit:

| Action | Key |
|---|---|
| Save | `<C-s>` (normal/insert) |
| Quit current window | `<leader>q` |

---

## 12) Completion menu navigation (nvim-cmp)

In insert mode, when the completion menu is visible:

| Action | Key |
|---|---|
| Trigger completion | `<C-Space>` |
| Next item | `<Tab>` |
| Previous item | `<S-Tab>` |
| Confirm | `<CR>` |
| Scroll docs up | `<C-b>` |
| Scroll docs down | `<C-f>` |
| Cancel | `<C-e>` |

---

## 13) Competitive programming workflow (optional, but built-in)

From `lua/cp.lua`:

| Action | Key |
|---|---|
| Open `input.txt` + `expected.txt` splits | `<leader>t` |
| Open runner (press again to run with pasted stdin) | `<leader>r` |
| Compile/run using `input.txt` and diff vs `expected.txt` | `<leader>R` |

Expected directory layout for `<leader>t` / `<leader>R`:
```
problem/
  solution.cpp
  input.txt
  expected.txt
```

---

## 14) Plugin manager + tooling quick commands

Your plugin manager is **lazy.nvim**.

Useful commands:
- `:Lazy` — open plugin UI
- `:Lazy sync` — install/update plugins
- `:Mason` — manage/install language servers

---

## 15) A good “learn this first” path

1. **Files**: `<leader>ff`, `<leader>fg`, `<leader>fb`
2. **Splits**: `<C-h/j/k/l>`
3. **LSP**: `gd`, `K`, `gr`, `<leader>rn`, `<leader>f`
4. **Diagnostics**: `[d`, `]d`, `<leader>e`
5. **Terminal**: `<leader>tt`
6. **Explorer**: `<leader>o`
