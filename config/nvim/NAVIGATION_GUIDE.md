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

## 13) Competitive programming workflow

From `lua/cp.lua`. **All execution is async — Neovim never freezes**, even on infinite loops.

| Action | Key |
|---|---|
| Open `input.txt` + `expected.txt` splits | `<leader>t` |
| Open runner (press again to run, **1s timeout**) | `<leader>r` |
| Compile/run + diff vs `expected.txt` (**1s timeout**) | `<leader>R` |
| Brute force runner (**30s timeout**) | `<leader>b` |
| Brute force compile/run + diff (**30s timeout**) | `<leader>B` |
| Kill running process immediately | `<leader>k` |

### Runner workflow (`<leader>r` / `<leader>b`)

1. First press: Opens input/output panels on the right
2. Paste your test input in the `[CP Input]` buffer
3. Second press: Compiles and runs, shows output with timing
4. Use `<leader>b` instead for brute force solutions that need more than 1 second

### Diff workflow (`<leader>R` / `<leader>B`)

1. Create `input.txt` and `expected.txt` in your working directory
2. Press `<leader>R` to compile, run, and open a diff view
3. Green = matches expected, Red = differs
4. Use `<leader>B` for brute force solutions

### Timeout & safety behavior

- Default timeout (**1s**): process is killed with SIGKILL after 1 second
- Brute force timeout (**30s**): same mechanism, longer leash
- On TLE: output shows `⏱ TLE — Time Limit Exceeded`
- `<leader>k` kills any running process at any time
- If a process is already running, pressing run again warns you instead of spawning a second one

### Output information

The output shows:
- **Timing**: `--- 12 ms ---` or `--- 1.25 s ---` at the bottom
- **TLE**: `⏱ TLE — Time Limit Exceeded (1000 ms)` when timeout fires
- **Runtime errors**: Segfaults, aborts, and other crashes are clearly labeled
- **Compile errors**: Shown if compilation fails (compilation is synchronous and safe)

### Supported languages

| Language | Extensions | Compiler/Runtime |
|----------|------------|------------------|
| C++ | `.cpp`, `.cc`, `.cxx`, `.C` | g++/clang++ with sanitizers |
| C | `.c` | gcc/clang with sanitizers |
| Python | `.py` | python3/python |
| Java | `.java` | javac + java |
| JavaScript | `.js`, `.mjs` | node |
| Go | `.go` | go run |
| Rust | `.rs` | rustc |

### C/C++ debug features

Compilation includes `-fsanitize=address,undefined` which catches:
- Buffer overflows
- Use-after-free
- Undefined behavior
- Out-of-bounds access

Expected directory layout:
```
problem/
  solution.cpp
  input.txt      # Your test input
  expected.txt   # Expected output (for diff)
  output.txt     # Generated by <leader>R
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
