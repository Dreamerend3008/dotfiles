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
-- ║  Supported: C, C++, Python, Java, JavaScript, Go, Rust                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Helpers                                                                      │
-- └────────────────────────────────────────────────────────────────────────────┘
local function ensure_file(path)
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
end

local function find_executable(candidates)
  for _, cmd in ipairs(candidates) do
    if vim.fn.executable(cmd) == 1 then
      return cmd
    end
  end
  return nil
end

local function se(x)
  return vim.fn.shellescape(x)
end

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Language support - add new languages here                                    │
-- └────────────────────────────────────────────────────────────────────────────┘
local function get_cmd_for_file(file, ext, bin)
  -- C++
  if ext == "cpp" or ext == "cc" or ext == "cxx" or ext == "C" then
    local cxx = find_executable({ "g++", "clang++", "c++" })
    if not cxx then return nil, "No C++ compiler found (g++, clang++)" end
    return {
      compile = string.format("%s -std=c++17 -O2 -Wall -Wextra -fsanitize=address,undefined -g %s -o %s", cxx, se(file), se(bin)),
      run = bin,
    }
  end

  -- C
  if ext == "c" then
    local cc = find_executable({ "gcc", "clang", "cc" })
    if not cc then return nil, "No C compiler found (gcc, clang)" end
    return {
      compile = string.format("%s -std=c11 -O2 -Wall -Wextra -fsanitize=address,undefined -g %s -o %s", cc, se(file), se(bin)),
      run = bin,
    }
  end

  -- Python
  if ext == "py" then
    local py = find_executable({ "python3", "python" })
    if not py then return nil, "No Python interpreter found" end
    return { run = string.format("%s %s", py, se(file)) }
  end

  -- Java
  if ext == "java" then
    local javac = find_executable({ "javac" })
    local java = find_executable({ "java" })
    if not javac or not java then return nil, "No Java compiler/runtime found" end
    local classname = vim.fn.fnamemodify(file, ":t:r")
    local dir = vim.fn.fnamemodify(file, ":h")
    return {
      compile = string.format("cd %s && %s %s", se(dir), javac, se(file)),
      run = string.format("cd %s && %s %s", se(dir), java, classname),
    }
  end

  -- JavaScript/Node.js
  if ext == "js" or ext == "mjs" then
    local node = find_executable({ "node", "nodejs" })
    if not node then return nil, "No Node.js runtime found" end
    return { run = string.format("%s %s", node, se(file)) }
  end

  -- Go
  if ext == "go" then
    local go = find_executable({ "go" })
    if not go then return nil, "No Go compiler found" end
    return { run = string.format("%s run %s", go, se(file)) }
  end

  -- Rust
  if ext == "rs" then
    local rustc = find_executable({ "rustc" })
    if not rustc then return nil, "No Rust compiler found" end
    return {
      compile = string.format("%s -O %s -o %s", rustc, se(file), se(bin)),
      run = bin,
    }
  end

  return nil, "Unsupported file type: " .. ext
end

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>t → Open test files                                                  │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.keymap.set("n", "<leader>t", function()
  local cwd = vim.fn.getcwd()
  local input = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"

  ensure_file(input)
  ensure_file(expected)

  vim.cmd("vsplit " .. vim.fn.fnameescape(input))
  vim.cmd("vertical resize 30")
  vim.cmd("setlocal winfixwidth")
  vim.cmd("split " .. vim.fn.fnameescape(expected))
  vim.cmd("wincmd h")
end, { desc = "Open test files (input + expected)" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>r → CP runner (paste input → get output)                              │
-- └────────────────────────────────────────────────────────────────────────────┘
local cp_input_buf = nil
local cp_output_buf = nil

local function find_win_for_buf(buf)
  if not buf then return nil end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

local function get_or_create_buf(name, modifiable)
  local buf = (name == "input") and cp_input_buf or cp_output_buf

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    if name == "input" then
      cp_input_buf = buf
    else
      cp_output_buf = buf
    end

    pcall(vim.api.nvim_buf_set_name, buf, name == "input" and "[CP Input]" or "[CP Output]")
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = modifiable
  end

  return buf
end

local function open_runner()
  local input_buf = get_or_create_buf("input", true)
  local output_buf = get_or_create_buf("output", false)

  local input_win = find_win_for_buf(input_buf)
  local output_win = find_win_for_buf(output_buf)

  if input_win and output_win then
    return true -- already open
  end

  vim.cmd("vsplit")
  vim.cmd("vertical resize 44")
  vim.api.nvim_win_set_buf(0, input_buf)
  vim.bo[input_buf].modifiable = true

  vim.cmd("split")
  vim.cmd("resize 12")
  vim.api.nvim_win_set_buf(0, output_buf)

  local iw = find_win_for_buf(input_buf)
  if iw then vim.api.nvim_set_current_win(iw) end
  return false
end

local function runner_run()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("CP: No file open", vim.log.levels.ERROR)
    return
  end

  if vim.bo.modified then
    vim.cmd("silent write")
  end

  local ext = vim.fn.expand("%:e"):lower()
  local cache_dir = vim.fn.stdpath("cache") .. "/cp"
  vim.fn.mkdir(cache_dir, "p")
  local base = vim.fn.fnamemodify(file, ":t:r")
  local bin = cache_dir .. "/" .. base

  local cmd, err = get_cmd_for_file(file, ext, bin)
  if not cmd then
    vim.notify("CP: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  local input_buf = get_or_create_buf("input", true)
  local output_buf = get_or_create_buf("output", false)

  local input_lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local input = table.concat(input_lines, "\n")
  if input ~= "" then input = input .. "\n" end

  local out = ""

  -- Compile if needed
  if cmd.compile then
    vim.notify("Compiling...", vim.log.levels.INFO)
    out = vim.fn.system(cmd.compile .. " 2>&1")
    if vim.v.shell_error ~= 0 then
      vim.bo[output_buf].modifiable = true
      vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split("COMPILE ERROR:\n" .. out, "\n"))
      vim.bo[output_buf].modifiable = false
      vim.notify("Compilation failed!", vim.log.levels.ERROR)
      return
    end
  end

  -- Run with timing
  vim.notify("Running...", vim.log.levels.INFO)
  local run_cmd = cmd.run .. " 2>&1"
  local start_time = vim.loop.hrtime()
  out = vim.fn.system(run_cmd, input)
  local elapsed_ms = (vim.loop.hrtime() - start_time) / 1e6
  local exit_code = vim.v.shell_error

  -- Check for runtime errors (segfault, etc.)
  local prefix = ""
  if exit_code ~= 0 then
    if exit_code == 139 or exit_code == 11 then
      prefix = "SEGMENTATION FAULT (exit " .. exit_code .. "):\n"
    elseif exit_code == 134 or exit_code == 6 then
      prefix = "ABORTED (exit " .. exit_code .. "):\n"
    elseif exit_code == 136 or exit_code == 8 then
      prefix = "FLOATING POINT EXCEPTION (exit " .. exit_code .. "):\n"
    else
      prefix = "RUNTIME ERROR (exit " .. exit_code .. "):\n"
    end
    vim.notify("Runtime error!", vim.log.levels.ERROR)
  end

  -- Format time nicely
  local time_str
  if elapsed_ms < 1000 then
    time_str = string.format("%.0f ms", elapsed_ms)
  else
    time_str = string.format("%.2f s", elapsed_ms / 1000)
  end
  local footer = "\n--- " .. time_str .. " ---"

  vim.bo[output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split(prefix .. out .. footer, "\n"))
  vim.bo[output_buf].modifiable = false
end

vim.keymap.set("n", "<leader>r", function()
  local already_open = open_runner()
  if already_open then
    runner_run()
  end
end, { desc = "CP runner (open / run)" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>R → Compile, run, and diff                                            │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.keymap.set("n", "<leader>R", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("CP: No file open", vim.log.levels.ERROR)
    return
  end

  if vim.bo.modified then
    vim.cmd("silent write")
  end

  local cwd = vim.fn.getcwd()
  local ext = vim.fn.expand("%:e"):lower()
  local bin = cwd .. "/program.out"
  local input = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"
  local output = cwd .. "/output.txt"

  ensure_file(input)
  ensure_file(expected)

  local cmd, err = get_cmd_for_file(file, ext, bin)
  if not cmd then
    vim.notify("CP: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Compile if needed
  if cmd.compile then
    vim.notify("Compiling...", vim.log.levels.INFO)
    local compile_out = vim.fn.system(cmd.compile .. " 2>&1")
    if vim.v.shell_error ~= 0 then
      vim.notify("Compilation failed!\n" .. compile_out, vim.log.levels.ERROR)
      return
    end
  end

  -- Run with input file and timing
  vim.notify("Running...", vim.log.levels.INFO)
  local run_cmd = string.format("%s < %s > %s 2>&1", se(cmd.run), se(input), se(output))
  local start_time = vim.loop.hrtime()
  vim.fn.system(run_cmd)
  local elapsed_ms = (vim.loop.hrtime() - start_time) / 1e6
  local exit_code = vim.v.shell_error

  -- Format time
  local time_str
  if elapsed_ms < 1000 then
    time_str = string.format("%.0f ms", elapsed_ms)
  else
    time_str = string.format("%.2f s", elapsed_ms / 1000)
  end

  -- Check for runtime errors and prepend to output file
  local existing = vim.fn.readfile(output)
  if exit_code ~= 0 then
    local error_msg
    if exit_code == 139 or exit_code == 11 then
      error_msg = "SEGMENTATION FAULT (exit " .. exit_code .. ")"
    elseif exit_code == 134 or exit_code == 6 then
      error_msg = "ABORTED (exit " .. exit_code .. ")"
    elseif exit_code == 136 or exit_code == 8 then
      error_msg = "FLOATING POINT EXCEPTION (exit " .. exit_code .. ")"
    else
      error_msg = "RUNTIME ERROR (exit " .. exit_code .. ")"
    end
    table.insert(existing, 1, error_msg)
    table.insert(existing, 2, "---")
    vim.notify(error_msg, vim.log.levels.ERROR)
  end
  -- Append timing
  table.insert(existing, "--- " .. time_str .. " ---")
  vim.fn.writefile(existing, output)

  -- Open diff view
  vim.cmd("vsplit " .. vim.fn.fnameescape(expected))
  vim.cmd("vertical resize 30")
  vim.cmd("setlocal winfixwidth")
  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(output))
  vim.cmd("wincmd h")
end, { desc = "Compile & run, diff output vs expected" })
