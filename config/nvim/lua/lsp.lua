-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              LSP.LUA                                          ║
-- ║                                                                               ║
-- ║  Language Server Protocol configuration.                                     ║
-- ║                                                                               ║
-- ║  LSP provides:                                                               ║
-- ║    - Autocompletion suggestions                                              ║
-- ║    - Go to definition (gd)                                                   ║
-- ║    - Find references                                                         ║
-- ║    - Hover documentation (K)                                                 ║
-- ║    - Diagnostics (errors, warnings)                                          ║
-- ║                                                                               ║
-- ║  Mason automatically installs the language servers listed below.            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Capabilities                                                                │
-- └────────────────────────────────────────────────────────────────────────────┘
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- Mason is optional here; config expects system-managed binaries.
pcall(function()
  require("mason").setup()
end)

-- clangd (C/C++): allow querying g++ for correct libstdc++ include paths.
local query_driver = table.concat({
  "--query-driver=/usr/bin/*g++*",
  "/usr/bin/*c++*",
  vim.fn.expand("$HOME/.nix-profile/bin/*g++*"),
  "/run/current-system/sw/bin/*g++*",
  "/nix/store/*/bin/*g++*",
}, ",")

local function setup_native()
  vim.lsp.config("*", {
    capabilities = capabilities,
  })

  local clangd_cmd = vim.fn.exepath("clangd")
  if clangd_cmd == "" then
    clangd_cmd = "clangd"
  end

  vim.lsp.config("clangd", {
    cmd = {
      clangd_cmd,
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      query_driver,
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_dir = function(bufnr, on_dir)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      if fname == "" then
        return on_dir(vim.fn.getcwd())
      end

      local root = vim.fs.root(bufnr, { "compile_commands.json", "compile_flags.txt", ".git" })
      if not root then
        root = vim.fs.dirname(fname)
      end
      on_dir(root)
    end,
    init_options = {
      fallbackFlags = { "-std=gnu++17" },
    },
  })
  vim.lsp.enable("clangd")

  if vim.fn.exepath("lua-language-server") ~= "" then
    vim.lsp.config("lua_ls", {
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
    })
    vim.lsp.enable("lua_ls")
  end

  if vim.fn.exepath("pyright-langserver") ~= "" then
    vim.lsp.config("pyright", {
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
    })
    vim.lsp.enable("pyright")
  end
end

local function setup_legacy()
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    return
  end

  local util = require("lspconfig.util")

  local clangd_cmd = vim.fn.exepath("clangd")
  if clangd_cmd == "" then
    clangd_cmd = "clangd"
  end

  lspconfig.clangd.setup({
    capabilities = capabilities,
    root_dir = function(fname)
      return util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
        or util.path.dirname(fname)
    end,
    single_file_support = true,
    cmd = {
      clangd_cmd,
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      query_driver,
    },
    init_options = {
      fallbackFlags = { "-std=gnu++17" },
    },
  })

  if vim.fn.exepath("lua-language-server") ~= "" then
    lspconfig.lua_ls.setup({ capabilities = capabilities })
  end

  if vim.fn.exepath("pyright-langserver") ~= "" then
    lspconfig.pyright.setup({ capabilities = capabilities })
  end
end

if vim.lsp and vim.lsp.config and vim.lsp.enable then
  setup_native()
else
  setup_legacy()
end

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ LSP Keymaps                                                                 │
-- │                                                                             │
-- │ These keymaps only activate when an LSP is attached to the buffer.        │
-- └────────────────────────────────────────────────────────────────────────────┘
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local opts = { buffer = event.buf }
    
    -- Go to definition (where function/variable is defined)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    
    -- Go to declaration
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    
    -- Show hover documentation
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    
    -- Go to implementation
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    
    -- Find all references
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    
    -- Rename symbol (renames everywhere it's used)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    
    -- Code actions (quick fixes, refactoring)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    
    -- Format code
    vim.keymap.set("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, opts)
  end,
})
