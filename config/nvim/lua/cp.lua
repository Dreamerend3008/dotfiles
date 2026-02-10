-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              CP.LUA                                           ║
-- ║                                                                               ║
-- ║  Competitive Programming helpers for Neovim.                                 ║
-- ║                                                                               ║
-- ║  Keybindings:                                                                ║
-- ║    <Space>t  - Open test files (input.txt + expected.txt)                   ║
-- ║    <Space>r  - Open runner (2nd press runs with pasted input)               ║
-- ║    <Space>R  - Compile/run using input.txt and diff vs expected.txt         ║
-- ║                                                                               ║
-- ║  Expected folder structure (for <Space>t / <Space>R):                        ║
-- ║    problem/                                                                  ║
-- ║      solution.cpp    ← Your code                                             ║
-- ║      input.txt       ← Test input                                            ║
-- ║      expected.txt    ← Expected output                                       ║
-- ║      output.txt      ← Generated output (auto-created)                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Helpers                                                                      │
-- └────────────────────────────────────────────────────────────────────────────┘
local function ensure_file(path)
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
end


-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>t → Open test files                                                  │
-- │                                                                             │
-- │ Opens input.txt and expected.txt in splits to the right.                   │
-- │ Creates the files if they don't exist.                                     │
-- │                                                                             │
-- │ Layout after pressing <Space>t:                                            │
-- │ ┌─────────────────┬──────────────┐                                         │
-- │ │                 │  input.txt   │                                         │
-- │ │  solution.cpp   ├──────────────┤                                         │
-- │ │                 │ expected.txt │                                         │
-- │ └─────────────────┴──────────────┘                                         │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.keymap.set("n", "<leader>t", function()
  local cwd      = vim.fn.getcwd()
  local input    = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"

  -- Create files if they don't exist
  ensure_file(input)
  ensure_file(expected)

  -- Open input.txt in a vertical split (right side)
  vim.cmd("vsplit " .. vim.fn.fnameescape(input))
  vim.cmd("vertical resize 30")       -- Set width
  vim.cmd("setlocal winfixwidth")     -- Lock width
  
  -- Open expected.txt below input.txt
  vim.cmd("split " .. vim.fn.fnameescape(expected))
  
  -- Return focus to main window (left)
  vim.cmd("wincmd h")
end, { desc = "Open test files (input + expected)" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>r → CP runner (paste input → get output)                              │
-- │                                                                             │
-- │ First press: opens a right-side runner with two scratch buffers:            │
-- │   [CP Input]  (paste stdin here)                                            │
-- │   [CP Output] (stdout/stderr shown here)                                    │
-- │ Second press: compiles (if needed) and runs using [CP Input] as stdin.      │
-- │                                                                             │
-- │ Works on Ubuntu + WSL (uses standard shell commands).                       │
-- └────────────────────────────────────────────────────────────────────────────┘
local function find_win_for_buf(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function runner_buf(name)
  local key = name == "input" and "cp_input_buf" or "cp_output_buf"
  local buf = vim.t[key]

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.t[key] = buf

    vim.api.nvim_buf_set_name(buf, name == "input" and "[CP Input]" or "[CP Output]")
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "text"
    if name ~= "input" then
      vim.bo[buf].modifiable = false
    end
  end

  return buf
end

local function open_runner()
  local input_buf = runner_buf("input")
  local output_buf = runner_buf("output")

  local input_win = find_win_for_buf(input_buf)
  local output_win = find_win_for_buf(output_buf)

  if input_win and output_win then
    return true
  end

  local main_win = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  vim.cmd("vertical resize 44")
  vim.api.nvim_win_set_buf(0, input_buf)

  vim.cmd("split")
  vim.cmd("resize 12")
  vim.api.nvim_win_set_buf(0, output_buf)

  vim.api.nvim_set_current_win(find_win_for_buf(input_buf) or main_win)
  return false
end

local function get_cmd_for_current_file()
  local file = vim.fn.expand("%:p")
  local ext = vim.fn.expand("%:e")

  local cache_dir = vim.fn.stdpath("cache") .. "/cp"
  vim.fn.mkdir(cache_dir, "p")

  local base = vim.fn.fnamemodify(file, ":t:r")
  local bin = cache_dir .. "/" .. base .. ".out"

  local function se(x)
    return vim.fn.shellescape(x)
  end

  if ext == "cpp" or ext == "cc" or ext == "cxx" then
    local cxx = vim.fn.executable("g++") == 1 and "g++" or "clang++"
    local compile = string.format("%s -std=gnu++17 -O2 %s -o %s", cxx, se(file), se(bin))
    return { compile = compile, run = se(bin) }
  end

  if ext == "c" then
    local cc = vim.fn.executable("gcc") == 1 and "gcc" or "clang"
    local compile = string.format("%s -O2 %s -o %s", cc, se(file), se(bin))
    return { compile = compile, run = se(bin) }
  end

  if ext == "py" then
    local py = vim.fn.executable("python3") == 1 and "python3" or "python"
    return { run = string.format("%s %s", py, se(file)) }
  end

  return nil
end

local function runner_run()
  if vim.bo.modified then
    vim.cmd("write")
  end

  local input_buf = runner_buf("input")
  local output_buf = runner_buf("output")

  local input = table.concat(vim.api.nvim_buf_get_lines(input_buf, 0, -1, false), "\n")
  if input ~= "" then
    input = input .. "\n"
  end

  local cmd = get_cmd_for_current_file()
  if not cmd then
    vim.notify("CP runner: unsupported file type", vim.log.levels.ERROR)
    return
  end

  local out = ""

  if cmd.compile then
    vim.notify("Compiling...", vim.log.levels.INFO)
    out = vim.fn.system(cmd.compile .. " 2>&1")
    if vim.v.shell_error ~= 0 then
      -- show compile output in the runner
      vim.bo[output_buf].modifiable = true
      vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split(out, "\n", { plain = true }))
      vim.bo[output_buf].modifiable = false
      return
    end
  end

  out = vim.fn.system(cmd.run .. " 2>&1", input)

  vim.bo[output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split(out, "\n", { plain = true }))
  vim.bo[output_buf].modifiable = false
end

vim.keymap.set("n", "<leader>r", function()
  local already_open = open_runner()
  if already_open then
    runner_run()
  end
end, { desc = "CP runner (open / run)" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>R → Compile, run, and diff (original workflow)                        │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.keymap.set("n", "<leader>R", function()
  -- Save file if modified
  if vim.bo.modified then
    vim.cmd("write")
  end

  local cwd      = vim.fn.getcwd()
  local file     = vim.fn.expand("%:p")          -- Full path of current file
  local bin      = cwd .. "/program.out"         -- Compiled binary
  local input    = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"
  local output   = cwd .. "/output.txt"

  ensure_file(input)
  ensure_file(expected)

  local compile_cmd = string.format("g++ -std=gnu++17 -O2 %s -o %s", vim.fn.shellescape(file), vim.fn.shellescape(bin))
  vim.notify("Compiling " .. file .. "...", vim.log.levels.INFO)
  vim.fn.system(compile_cmd .. " 2>&1")

  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation failed!", vim.log.levels.ERROR)
    return
  end

  local run_cmd = string.format("%s < %s > %s", vim.fn.shellescape(bin), vim.fn.shellescape(input), vim.fn.shellescape(output))
  vim.fn.system(run_cmd .. " 2>&1")

  vim.cmd("vsplit " .. vim.fn.fnameescape(expected))
  vim.cmd("vertical resize 30")
  vim.cmd("setlocal winfixwidth")
  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(output))
  vim.cmd("wincmd h")
end, { desc = "Compile & run current file, diff output vs expected" })
