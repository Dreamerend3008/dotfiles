-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                            COMPLETION.LUA                                     ║
-- ║                                                                               ║
-- ║  Autocompletion configuration using nvim-cmp.                                ║
-- ║                                                                               ║
-- ║  Keybindings:                                                                ║
-- ║    <Tab>       - Select next completion item                                 ║
-- ║    <S-Tab>     - Select previous completion item                             ║
-- ║    <CR>        - Confirm selection (Enter)                                   ║
-- ║    <C-Space>   - Manually trigger completion                                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_autopairs = require("nvim-autopairs.completion.cmp")

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Main CMP Setup                                                              │
-- └────────────────────────────────────────────────────────────────────────────┘
cmp.setup({
  -- Snippet expansion (required for snippet completions)
  snippet = {
    expand = function(args) 
      luasnip.lsp_expand(args.body) 
    end,
  },
  
  -- ┌──────────────────────────────────────────────────────────────────────────┐
  -- │ Keybindings for completion menu                                          │
  -- └──────────────────────────────────────────────────────────────────────────┘
  mapping = cmp.mapping.preset.insert({
    -- Manually trigger completion
    ["<C-Space>"] = cmp.mapping.complete(),
    
    -- Confirm selection with Enter
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    
    -- Navigate with Tab/Shift+Tab
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    
    -- Scroll documentation
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    
    -- Cancel completion
    ["<C-e>"] = cmp.mapping.abort(),
  }),
  
  -- ┌──────────────────────────────────────────────────────────────────────────┐
  -- │ Completion Sources                                                        │
  -- │                                                                           │
  -- │ Order matters! First sources have higher priority.                       │
  -- └──────────────────────────────────────────────────────────────────────────┘
  sources = cmp.config.sources({
    { name = "nvim_lsp" },   -- LSP completions (functions, variables, etc.)
    { name = "luasnip" },    -- Snippet completions
    { name = "buffer" },     -- Words from current buffer
    { name = "path" },       -- File paths
  }),
  
  -- ┌──────────────────────────────────────────────────────────────────────────┐
  -- │ Appearance                                                                │
  -- └──────────────────────────────────────────────────────────────────────────┘
  window = {
    completion = cmp.config.window.bordered({
      winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
      col_offset = -3,
      side_padding = 0,
    }),
    documentation = cmp.config.window.bordered(),
  },
  
  -- Format how completions are displayed
  formatting = {
    fields = { "abbr", "kind" },
    format = function(entry, vim_item)
      -- Truncate long completions
      vim_item.abbr = string.sub(vim_item.abbr, 1, 30)
      return vim_item
    end,
  },
  
  -- Show ghost text (preview of completion)
  experimental = { 
    ghost_text = true 
  },
})

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ Autopairs Integration                                                       │
-- │                                                                             │
-- │ Automatically add closing bracket after completing a function.             │
-- │ Example: typing "print" and selecting it → "print()"                       │
-- └────────────────────────────────────────────────────────────────────────────┘
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
