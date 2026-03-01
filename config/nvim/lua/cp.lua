-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              CP.LUA                                           ║
-- ║                                                                               ║
-- ║  Competitive Programming helpers for Neovim.                                 ║
-- ║                                                                               ║
-- ║  Keybindings:                                                                ║
-- ║    <Space>t  - Open test files (input.txt + expected.txt)                   ║
-- ║    <Space>r  - Open runner (2nd press runs, 1s timeout)                     ║
-- ║    <Space>R  - Compile/run + diff vs expected.txt (1s timeout)              ║
-- ║    <Space>b  - Brute force runner (30s timeout)                             ║
-- ║    <Space>B  - Brute force compile/run + diff (30s timeout)                 ║
-- ║    <Space>k  - Kill running process                                         ║
-- ║                                                                               ║
-- ║  All execution is async — Neovim never freezes.                              ║
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

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Async job state                                                              │
-- └────────────────────────────────────────────────────────────────────────────┘
local cp_job_id = nil
local cp_timeout_timer = nil

local DEFAULT_TIMEOUT_MS = 1000
local BRUTE_TIMEOUT_MS = 30000

local function format_exit_code(exit_code)
  if exit_code == 139 or exit_code == 11 then
    return "SEGMENTATION FAULT (exit " .. exit_code .. ")"
  elseif exit_code == 134 or exit_code == 6 then
    return "ABORTED (exit " .. exit_code .. ")"
  elseif exit_code == 136 or exit_code == 8 then
    return "FLOATING POINT EXCEPTION (exit " .. exit_code .. ")"
  else
    return "RUNTIME ERROR (exit " .. exit_code .. ")"
  end
end

local function format_time(elapsed_ms)
  if elapsed_ms < 1000 then
    return string.format("%.0f ms", elapsed_ms)
  else
    return string.format("%.2f s", elapsed_ms / 1000)
  end
end

local function cp_kill()
  if cp_timeout_timer then
    cp_timeout_timer:stop()
    cp_timeout_timer:close()
    cp_timeout_timer = nil
  end
  if cp_job_id then
    pcall(vim.fn.jobstop, cp_job_id)
    cp_job_id = nil
  end
end

local function runner_run(timeout_ms)
  if cp_job_id then
    vim.notify("CP: Process already running — <Space>k to kill", vim.log.levels.WARN)
    return
  end

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

  -- Compile synchronously (fast, bounded)
  if cmd.compile then
    vim.notify("Compiling...", vim.log.levels.INFO)
    local out = vim.fn.system(cmd.compile .. " 2>&1")
    if vim.v.shell_error ~= 0 then
      vim.bo[output_buf].modifiable = true
      vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split("COMPILE ERROR:\n" .. out, "\n"))
      vim.bo[output_buf].modifiable = false
      vim.notify("Compilation failed!", vim.log.levels.ERROR)
      return
    end
  end

  -- Show running indicator
  vim.bo[output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, { "⏳ Running... (timeout: " .. format_time(timeout_ms) .. ")" })
  vim.bo[output_buf].modifiable = false
  vim.notify("Running...", vim.log.levels.INFO)

  -- Prepare input
  local input_lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local input_str = table.concat(input_lines, "\n")
  if input_str ~= "" then input_str = input_str .. "\n" end

  -- Async execution
  local stdout_chunks = {}
  local stderr_chunks = {}
  local start_time = vim.loop.hrtime()
  local timed_out = false

  cp_job_id = vim.fn.jobstart({ "sh", "-c", cmd.run .. " 2>&1" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout_chunks, line)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stderr_chunks, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      cp_job_id = nil
      if cp_timeout_timer then
        cp_timeout_timer:stop()
        cp_timeout_timer:close()
        cp_timeout_timer = nil
      end

      local elapsed_ms = (vim.loop.hrtime() - start_time) / 1e6

      vim.schedule(function()
        local result_lines = {}

        if timed_out then
          table.insert(result_lines, "⏱ TLE — Time Limit Exceeded (" .. format_time(timeout_ms) .. ")")
          table.insert(result_lines, "---")
          vim.notify("TLE! Process killed after " .. format_time(timeout_ms), vim.log.levels.WARN)
        elseif exit_code ~= 0 then
          table.insert(result_lines, format_exit_code(exit_code))
          table.insert(result_lines, "---")
          vim.notify("Runtime error!", vim.log.levels.ERROR)
        end

        -- Add output
        local out = table.concat(stdout_chunks, "\n")
        if out ~= "" then
          for _, line in ipairs(vim.split(out, "\n")) do
            table.insert(result_lines, line)
          end
        end

        -- Footer with timing
        table.insert(result_lines, "")
        table.insert(result_lines, "--- " .. format_time(elapsed_ms) .. " ---")

        if not vim.api.nvim_buf_is_valid(output_buf) then return end
        vim.bo[output_buf].modifiable = true
        vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, result_lines)
        vim.bo[output_buf].modifiable = false
      end)
    end,
  })

  if cp_job_id <= 0 then
    vim.notify("CP: Failed to start process", vim.log.levels.ERROR)
    cp_job_id = nil
    return
  end

  -- Send input to stdin
  if input_str ~= "" then
    vim.fn.chansend(cp_job_id, input_str)
  end
  vim.fn.chanclose(cp_job_id, "stdin")

  -- Set timeout timer
  cp_timeout_timer = vim.loop.new_timer()
  cp_timeout_timer:start(timeout_ms, 0, vim.schedule_wrap(function()
    if cp_job_id then
      timed_out = true
      pcall(vim.fn.jobstop, cp_job_id)
    end
    if cp_timeout_timer then
      cp_timeout_timer:stop()
      cp_timeout_timer:close()
      cp_timeout_timer = nil
    end
  end))
end

vim.keymap.set("n", "<leader>r", function()
  local already_open = open_runner()
  if already_open then
    runner_run(DEFAULT_TIMEOUT_MS)
  end
end, { desc = "CP runner (open / run, 1s timeout)" })

vim.keymap.set("n", "<leader>b", function()
  local already_open = open_runner()
  if already_open then
    runner_run(BRUTE_TIMEOUT_MS)
  end
end, { desc = "CP brute force runner (30s timeout)" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>R / <Space>B → Compile, run, and diff (async)                         │
-- └────────────────────────────────────────────────────────────────────────────┘
local function diff_run(timeout_ms)
  if cp_job_id then
    vim.notify("CP: Process already running — <Space>k to kill", vim.log.levels.WARN)
    return
  end

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
  local input_path = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"
  local output_path = cwd .. "/output.txt"

  ensure_file(input_path)
  ensure_file(expected)

  local cmd, err = get_cmd_for_file(file, ext, bin)
  if not cmd then
    vim.notify("CP: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Compile synchronously (fast, bounded)
  if cmd.compile then
    vim.notify("Compiling...", vim.log.levels.INFO)
    local compile_out = vim.fn.system(cmd.compile .. " 2>&1")
    if vim.v.shell_error ~= 0 then
      vim.notify("Compilation failed!\n" .. compile_out, vim.log.levels.ERROR)
      return
    end
  end

  vim.notify("Running... (timeout: " .. format_time(timeout_ms) .. ")", vim.log.levels.INFO)

  -- Async execution
  local stdout_chunks = {}
  local start_time = vim.loop.hrtime()
  local timed_out = false

  local run_shell = string.format("%s < %s 2>&1", se(cmd.run), se(input_path))

  cp_job_id = vim.fn.jobstart({ "sh", "-c", run_shell }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout_chunks, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      cp_job_id = nil
      if cp_timeout_timer then
        cp_timeout_timer:stop()
        cp_timeout_timer:close()
        cp_timeout_timer = nil
      end

      local elapsed_ms = (vim.loop.hrtime() - start_time) / 1e6

      vim.schedule(function()
        local result_lines = {}

        if timed_out then
          table.insert(result_lines, "⏱ TLE — Time Limit Exceeded (" .. format_time(timeout_ms) .. ")")
          table.insert(result_lines, "---")
          vim.notify("TLE! Process killed after " .. format_time(timeout_ms), vim.log.levels.WARN)
        elseif exit_code ~= 0 then
          local error_msg = format_exit_code(exit_code)
          table.insert(result_lines, error_msg)
          table.insert(result_lines, "---")
          vim.notify(error_msg, vim.log.levels.ERROR)
        end

        -- Add output
        local out = table.concat(stdout_chunks, "\n")
        if out ~= "" then
          for _, line in ipairs(vim.split(out, "\n")) do
            table.insert(result_lines, line)
          end
        end

        -- Footer with timing
        table.insert(result_lines, "--- " .. format_time(elapsed_ms) .. " ---")

        vim.fn.writefile(result_lines, output_path)

        -- Open diff view
        vim.cmd("vsplit " .. vim.fn.fnameescape(expected))
        vim.cmd("vertical resize 30")
        vim.cmd("setlocal winfixwidth")
        vim.cmd("vert diffsplit " .. vim.fn.fnameescape(output_path))
        vim.cmd("wincmd h")
      end)
    end,
  })

  if cp_job_id <= 0 then
    vim.notify("CP: Failed to start process", vim.log.levels.ERROR)
    cp_job_id = nil
    return
  end

  -- Set timeout timer
  cp_timeout_timer = vim.loop.new_timer()
  cp_timeout_timer:start(timeout_ms, 0, vim.schedule_wrap(function()
    if cp_job_id then
      timed_out = true
      pcall(vim.fn.jobstop, cp_job_id)
    end
    if cp_timeout_timer then
      cp_timeout_timer:stop()
      cp_timeout_timer:close()
      cp_timeout_timer = nil
    end
  end))
end

vim.keymap.set("n", "<leader>R", function()
  diff_run(DEFAULT_TIMEOUT_MS)
end, { desc = "Compile & run + diff (1s timeout)" })

vim.keymap.set("n", "<leader>B", function()
  diff_run(BRUTE_TIMEOUT_MS)
end, { desc = "Brute force compile & run + diff (30s timeout)" })

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ <Space>k → Kill running CP process                                           │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.keymap.set("n", "<leader>k", function()
  if cp_job_id then
    cp_kill()
    vim.notify("CP: Process killed", vim.log.levels.WARN)
  else
    vim.notify("CP: No process running", vim.log.levels.INFO)
  end
end, { desc = "Kill running CP process" })
