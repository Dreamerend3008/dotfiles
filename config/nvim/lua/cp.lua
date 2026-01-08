-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              CP.LUA                                           ║
-- ║                                                                               ║
-- ║  Competitive Programming helpers for Neovim.                                 ║
-- ║                                                                               ║
-- ║  Keybindings:                                                                ║
-- ║    <Space>t  - Open test files (input.txt + expected.txt)                   ║
-- ║    <Space>r  - Compile and run, diff output vs expected                     ║
-- ║                                                                               ║
-- ║  Expected folder structure:                                                  ║
-- ║    problem/                                                                  ║
-- ║      solution.cpp    ← Your code                                             ║
-- ║      input.txt       ← Test input                                            ║
-- ║      expected.txt    ← Expected output                                       ║
-- ║      output.txt      ← Generated output (auto-created)                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Helper: Create file if it doesn't exist                                     │
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
-- │ <Space>r → Compile, run, and diff                                           │
-- │                                                                             │
-- │ 1. Saves the current file                                                  │
-- │ 2. Compiles with g++ (C++17)                                               │
-- │ 3. Runs with input.txt as stdin                                            │
-- │ 4. Saves output to output.txt                                              │
-- │ 5. Opens a diff view: expected.txt vs output.txt                           │
-- │                                                                             │
-- │ If compilation fails, shows an error notification.                         │
-- │                                                                             │
-- │ Layout after pressing <Space>r:                                            │
-- │ ┌─────────────────┬──────────────────────────────┐                         │
-- │ │                 │ expected.txt │ output.txt    │                         │
-- │ │  solution.cpp   │   (diff view - highlights    │                         │
-- │ │                 │    differences in red/green) │                         │
-- │ └─────────────────┴──────────────────────────────┘                         │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.keymap.set("n", "<leader>r", function()
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

  -- Create test files if they don't exist
  ensure_file(input)
  ensure_file(expected)

  -- Compile
  local compile_cmd = string.format("g++ -std=c++17 -O2 %s -o %s", file, bin)
  vim.notify("Compiling " .. file .. "...", vim.log.levels.INFO)
  vim.fn.system(compile_cmd)
  
  -- Check for compilation errors
  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation failed!", vim.log.levels.ERROR)
    return
  end

  -- Run with input, save to output
  local run_cmd = string.format("%s < %s > %s", bin, input, output)
  vim.fn.system(run_cmd)

  -- Open diff view: expected vs output
  vim.cmd("vsplit " .. vim.fn.fnameescape(expected))
  vim.cmd("vertical resize 30")
  vim.cmd("setlocal winfixwidth")
  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(output))
  
  -- Return focus to main window
  vim.cmd("wincmd h")
end, { desc = "Compile & run current cpp, diff output vs expected" })
