local function ensure_file(path)
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
end

-- <Space>t → open input & expected
vim.keymap.set("n", "<leader>t", function()
  local cwd      = vim.fn.getcwd()
  local input    = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"

  ensure_file(input)
  ensure_file(expected)

  vim.cmd("vsplit " .. vim.fn.fnameescape(input))
  vim.cmd("vertical resize 30")
  vim.cmd("setlocal winfixwidth")
  vim.cmd("split " .. vim.fn.fnameescape(expected))
  vim.cmd("wincmd h")
end, { desc = "Open test files (input + expected)" })

-- <Space>r → compile & run with input, diff with expected
vim.keymap.set("n", "<leader>r", function()
  if vim.bo.modified then vim.cmd("write") end

  local cwd      = vim.fn.getcwd()
  local file     = vim.fn.expand("%:p")
  local bin      = cwd .. "/program.out"
  local input    = cwd .. "/input.txt"
  local expected = cwd .. "/expected.txt"
  local output   = cwd .. "/output.txt"

  ensure_file(input)
  ensure_file(expected)

  local compile_cmd = string.format("g++ -std=c++17 -O2 %s -o %s", file, bin)
  vim.notify("Compiling " .. file .. "...", vim.log.levels.INFO)
  vim.fn.system(compile_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation failed!", vim.log.levels.ERROR)
    return
  end

  local run_cmd = string.format("%s < %s > %s", bin, input, output)
  vim.fn.system(run_cmd)

  vim.cmd("vsplit " .. vim.fn.fnameescape(expected))
  vim.cmd("vertical resize 30")
  vim.cmd("setlocal winfixwidth")
  vim.cmd("vert diffsplit " .. vim.fn.fnameescape(output))
  vim.cmd("wincmd h")
end, { desc = "Compile & run current cpp, diff output vs expected" })

