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

local lspconfig = require("lspconfig")

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Capabilities                                                                │
-- │                                                                             │
-- │ This tells the LSP what features our completion plugin supports.           │
-- └────────────────────────────────────────────────────────────────────────────┘
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Mason LSP Config                                                            │
-- │                                                                             │
-- │ ensure_installed: LSPs that will be automatically installed                │
-- │                                                                             │
-- │ Available servers: https://github.com/williamboman/mason-lspconfig.nvim    │
-- │                                                                             │
-- │ Add more as needed:                                                         │
-- │   "tsserver"     - TypeScript/JavaScript                                   │
-- │   "rust_analyzer" - Rust                                                   │
-- │   "gopls"        - Go                                                      │
-- │   "bashls"       - Bash                                                    │
-- │   "jsonls"       - JSON                                                    │
-- └────────────────────────────────────────────────────────────────────────────┘
require("mason-lspconfig").setup({
  ensure_installed = { 
    "clangd",     -- C/C++
    "lua_ls",     -- Lua
    "pyright",    -- Python
  },
})

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Configure Language Servers                                                  │
-- │                                                                             │
-- │ Each server is set up with the same capabilities.                          │
-- │ Add custom settings per-server if needed.                                  │
-- └────────────────────────────────────────────────────────────────────────────┘
local servers = { "clangd", "lua_ls", "pyright" }

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = capabilities,
  })
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
