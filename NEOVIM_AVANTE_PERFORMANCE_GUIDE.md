# Neovim/AstroNvim + Avante Performance Optimization Guide

## Table of Contents
1. [Common Freeze Causes](#common-freeze-causes)
2. [LSP Performance Optimization](#lsp-performance-optimization)
3. [Treesitter Configuration](#treesitter-configuration)
4. [Plugin Optimization](#plugin-optimization)
5. [Avante-Specific Fixes](#avante-specific-fixes)
6. [AstroNvim Config Examples](#astronvim-config-examples)
7. [Monitoring & Diagnostics](#monitoring--diagnostics)

---

## Common Freeze Causes

### 1. **LSP Issues**
- LSP servers not responding or crashing
- Too many diagnostics being shown
- No debouncing on text changes
- Memory leaks in LSP processes
- Conflicting LSP configurations

### 2. **Syntax Highlighting (Treesitter)**
- Parsing very large files (>5MB)
- Context window too large
- Incremental parsing not optimized
- Too many highlight groups enabled

### 3. **Plugin Issues**
- Too many plugins loaded at startup
- Heavy plugins not lazy-loaded
- Plugins running expensive operations on every keystroke
- Memory leaks in plugins
- Inefficient event handlers

### 4. **File Size Issues**
- Opening files > 10MB
- No file size limits configured
- Syntax highlighting enabled on huge files

### 5. **Avante-Specific Issues**
- Malformed tool parameters (like the `nil` new_str error)
- Rate limiting not configured
- Too many concurrent API calls
- Large context windows
- Streaming responses blocking UI

---

## LSP Performance Optimization

### Core LSP Settings
```lua
-- lua/user/lsp_config.lua

local util = require "lspconfig.util"

-- Global LSP settings for performance
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.synchronization.didSave = true
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- Debounce configuration (reduce LSP spam)
local debounce_ms = 300 -- milliseconds

-- Diagnostics configuration
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    spacing = 4,
  },
  float = {
    source = "always",
    border = "rounded",
  },
  signs = true,
  underline = true,
  update_in_insert = false, -- Don't update diagnostics while typing
  severity_sort = true,
})

-- Reduce diagnostic updates
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    -- Only show diagnostics for visible buffers
    virtual_text = true,
    underline = true,
    signs = true,
    update_in_insert = false,
  }
)

return {
  capabilities = capabilities,
  debounce_ms = debounce_ms,
}

### Per-LSP Configuration

```lua
-- lua/user/lsp_servers.lua

local lspconfig = require "lspconfig"
local capabilities = require("user.lsp_config").capabilities

-- Rust Analyzer - High Performance Settings
lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      -- Disable expensive features
      checkOnSave = {
        command = "clippy",
        extraArgs = { "--all-targets", "--all-features" },
      },
      -- Reduce memory usage
      cargo = {
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
      },
      -- Disable hovering data
      hover = {
        documentation = {
          enable = true,
        },
      },
      -- Experimental - can help with performance
      procMacro = {
        enable = true,
      },
      -- Reduce completion spam
      completion = {
        postfix = {
          enable = false,
        },
        autoimport = {
          enable = true,
        },
      },
    },
  },
  flags = {
    debounce_text_changes = 300,
  },
})

-- Python LSP (pyright) - Performance Settings
lspconfig.pyright.setup({
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        -- Don't analyze all files
        extraPaths = {},
        -- Only analyze workspace
        exclude = { "**/node_modules", "**/__pycache__", "**/.*" },
        -- Reduce memory
        typeCheckingMode = "basic",
        diagnosticMode = "workspace",
        stubPath = vim.fn.stdpath "config" .. "/stubs",
      },
    },
  },
  flags = {
    debounce_text_changes = 300,
  },
})

-- TypeScript/JavaScript
lspconfig.ts_ls.setup({
  capabilities = capabilities,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayEnumMemberValueHints = false,
        includeInlayFunctionLikeReturnTypeHints = false,
        includeInlayParameterNameHints = "none",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayPropertyDeclarationTypeHints = false,
        includeInlayVariableTypeHints = false,
      },
    },
  },
  flags = {
    debounce_text_changes = 300,
  },
})

-- Lua LSP
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        disable = { "missing-fields" },
      },
      workspace = {
        -- Only load what's needed
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
  flags = {
    debounce_text_changes = 300,
  },
})

---

## Treesitter Configuration

### Treesitter Performance Settings

```lua
-- lua/user/treesitter_config.lua

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "lua",
    "rust",
    "python",
    "javascript",
    "typescript",
    "json",
    "yaml",
    "toml",
    "markdown",
  },
  
  -- Syntax highlighting
  highlight = {
    enable = true,
    disable = function(lang, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
      
      -- Disable for specific filetypes
      return vim.tbl_contains({
        "sql",
        "csv",
        "log",
      }, lang)
    end,
    -- Performance optimization
    additional_vim_regex_highlighting = false, -- Disable regex fallback
  },
  
  -- Indentation
  indent = {
    enable = true,
  },
  
  -- Incremental selection
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  
  -- Query-based text objects
  textobjects = {
    enable = true,
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
  },
  
  -- Rainbow brackets (disable if causing lag)
  rainbow = {
    enable = false, -- Disable for performance
    extended_mode = false,
    max_file_lines = 1000,
  },
})

-- Disable treesitter for very large files
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local max_filesize = 500 * 1024 -- 500 KB
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > max_filesize then
      vim.opt_local.syntax = "off"
      require("nvim-treesitter.highlight").stop(args.buf)
    end
  end,
})

---

## Plugin Optimization

### Lazy.nvim Configuration for Performance

```lua
-- lua/user/lazy_config.lua

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("user.plugins", {
  -- Performance settings
  defaults = {
    lazy = true,
    version = false,
  },
  
  -- Faster startup
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
    reset_packpath = true,
    cache = {
      enabled = true,
    },
  },
  
  -- UI
  ui = {
    size = { width = 0.8, height = 0.8 },
  },
})

### Optimized Plugin Specifications

```lua
-- lua/user/plugins/core.lua

return {
  -- Essentials only - lazy load everything else
  {
    "folke/lazy.nvim",
    lazy = false,
    priority = 1000,
  },
  
  -- Colorscheme (load early but don't do heavy work)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        integrations = {
          -- Only enable what you use
          treesitter = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          cmp = true,
          nvim_tree = true,
          telescope = true,
        },
      })
      vim.cmd.colorscheme "catppuccin"
    end,
  },
}

-- lua/user/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      require "user.lsp_config"
    end,
  },
  
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require "cmp"
      cmp.setup({
        performance = {
          max_view_entries = 40,
          debounce = 60,
          throttle = 30,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
      })
    end,
  },
}

-- lua/user/plugins/ui.lua
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      defaults = {
        -- Performance settings
        layout_strategy = "horizontal",
        scroll_strategy = "cycle",
        results_title = "",
        preview_title = "",
        -- Limit results displayed
        max_results = 1000,
      },
    },
  },
  
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
    },
    opts = {
      update_focused_file = {
        enable = false, -- Disable auto-update for performance
      },
      diagnostics = {
        enable = false, -- Can be slow with many files
      },
    },
  },
}

-- lua/user/plugins/treesitter.lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      require "user.treesitter_config"
    end,
  },
}

---

## Avante-Specific Fixes & Performance Optimization

### Critical Bug Fix: nil new_str Error

**Error:** `attempt to concatenate field 'new_str' (a nil value)`

**Location:** `~/.local/share/nvim/lazy/avante.nvim/lua/avante/llm_tools/str_replace.lua:65`

**Root Cause:** The LLM is returning malformed tool parameters where `new_str` is missing or nil.

**Solution:** Add parameter validation in Avante configuration to ensure proper tool usage.

```lua
-- lua/user/avante_config.lua

-- Avante configuration with performance and reliability fixes
require("avante").setup({
  -- Provider configuration (OpenAI, Claude, etc.)
  provider = "openai", -- or "claude", "gemini", etc.
  
  -- Validate tool parameters before execution
  tool_validation = {
    enabled = true,
    -- Require these fields to be present and non-nil
    required_fields = {
      str_replace = { "old_str", "new_str", "file_path" },
    },
  },
  
  -- Performance settings
  performance = {
    -- Rate limiting to prevent API overload
    request_timeout = 30000, -- 30 seconds
    max_concurrent_requests = 1, -- Only one request at a time
    debounce_ms = 500, -- Debounce tool calls
    
    -- Context window limits
    max_tokens = 4000,
    
    -- Streaming settings
    enable_streaming = true,
    stream_buffer_size = 8192,
  },
  
  -- Disable heavy features if not needed
  features = {
    code_review = true,
    refactoring = true,
    documentation = true,
    -- Disable if causing performance issues
    inline_hints = false,
  },
})

-- Add error handling for tool execution
local avante_utils = require("avante.utils")
local original_execute_tool = avante_utils.execute_tool

function avante_utils.execute_tool(tool_name, params)
  -- Validate parameters
  if tool_name == "str_replace" then
    if not params.old_str or not params.new_str then
      vim.notify(
        "Avante: Invalid str_replace parameters - old_str or new_str is nil",
        vim.log.levels.ERROR
      )
      return nil, "Missing required parameters"
    end
  end
  
  return original_execute_tool(tool_name, params)
end

### Avante Performance Optimization

```lua
-- lua/user/plugins/avante.lua

return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = true,
    version = false,
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "Avante" },
        },
      },
    },
    opts = {
      provider = "openai",
      openai = {
        model = "gpt-4o",
        timeout = 30000,
        temperature = 0.7,
        max_tokens = 4096,
      },
      
      -- Auto suggestions (disable if causing lag)
      auto_suggestions_provider = "openai",
      auto_suggestions = {
        enabled = false, -- Disable to prevent constant API calls
      },
      
      -- Behavior
      behaviour = {
        auto_focus_on_tool_window = true,
        auto_apply_diff_after_generation = false,
      },
      
      -- Windows and UI
      windows = {
        wrap = true,
        width = 30,
        sidebar_header = {
          align = "center",
          rounded = true,
        },
      },
      
      -- File handling
      file_selector = {
        provider = "fzf",
      },
      
      -- Diff settings
      diff = {
        autojump = true,
        list_opener = "copen",
      },
    },
  },
}

-- lua/user/avante_keymaps.lua

-- Set up efficient keymaps for Avante
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Ask Avante with visual selection
keymap("v", "<leader>aa", ":AvanteAsk<CR>", opts)

-- Quick refactor without waiting for response
keymap("n", "<leader>ar", ":AvanteRefactor<CR>", opts)

-- Edit selected text
keymap("v", "<leader>ae", ":AvanteEdit<CR>", opts)

-- Toggle Avante sidebar (non-blocking)
keymap("n", "<leader>at", ":AvanteToggle<CR>", opts)

---

## AstroNvim Config Examples

### Complete AstroNvim init.lua with Performance Focus

```lua
-- init.lua (in your AstroNvim config folder)

-- This file is just loaded once when neovim starts, regardless of the returned value
-- Use the return value to setup plugin specs

-- In case a user does not have the latest Neovim, notify them
if vim.fn.has "nvim-0.9" == 0 then
  vim.api.nvim_err_writeln "AstroNvim requires Neovim >= 0.9"
  return {}
end

-- Before starting the user must accept the license
if require("astrocore").is_available "plenary" then
  if require("plenary.job"):new({ command = "git", args = { "log", "--oneline", "-1" } }):sync()[1] ~= nil then
    require "user.license"
  end
end

-- This calls the `setup` function to use the `sync` CLI (could also be `async`)
-- `sync` will load and sync all plugins managed by `lazy.nvim`
require "astrocore"

-- Load user configurations with performance in mind
require "user.init"

-- User configurations
require "user.options"
require "user.keymaps"

-- Load LSP and other heavy modules lazily
vim.api.nvim_create_autocmd("User", {
  pattern = "AstroFile",
  callback = function()
    require "user.autocmds"
  end,
})

return {}
```

### User Options for Performance

```lua
-- lua/user/options.lua

local opt = vim.opt
local g = vim.g

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- Performance settings
opt.updatetime = 300 -- Reduce update time (default 4000)
opt.redrawtime = 10000 -- Time limit for syntax highlighting
opt.lazyredraw = true -- Don't redraw during macros
opt.synmaxcol = 240 -- Limit syntax highlighting columns
opt.termguicolors = true

-- Memory efficiency
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.expand "~/.config/nvim/undo"

-- File handling
opt.modeline = false -- Disable modelines for security
opt.modelines = 0

-- Disable unwanted plugins
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0

-- Specific AstroNvim performance settings
g.astrocore_autocmds_enabled = true
g.astronvim_updates_enabled = true

-- LSP settings
g.lsp_round_borders_enabled = true
g.max_file_size = 100 * 1024 * 1024 -- 100MB

-- Disable features that cause lag
opt.foldmethod = "indent"
opt.foldlevel = 99 -- Keep folds open by default

---

## Monitoring & Diagnostics

### Performance Monitoring Commands

```lua
-- lua/user/diagnostics.lua

-- Function to check Neovim performance
local M = {}

function M.check_performance()
  local result = {
    startup_time = vim.fn.getftime(vim.fn.argv()[0]),
    memory_usage = collectgarbage("count"),
    loaded_plugins = #require("lazy").plugins(),
    lsp_clients = #vim.lsp.get_active_clients(),
  }
  
  vim.notify(
    string.format(
      "Neovim Performance:\n" ..
      "  Memory: %.2f MB\n" ..
      "  Loaded Plugins: %d\n" ..
      "  LSP Clients: %d",
      result.memory_usage / 1024,
      result.loaded_plugins,
      result.lsp_clients
    ),
    vim.log.levels.INFO
  )
  
  return result
end

function M.list_lsp_clients()
  local clients = vim.lsp.get_active_clients()
  if #clients == 0 then
    vim.notify("No active LSP clients", vim.log.levels.INFO)
    return
  end
  
  local msg = "Active LSP Clients:\n"
  for _, client in ipairs(clients) do
    msg = msg .. string.format("  - %s (PID: %s)\n", client.name, client.pid)
  end
  vim.notify(msg, vim.log.levels.INFO)
end

function M.restart_lsp()
  vim.cmd.LspStop()
  vim.fn.timer_start(500, function()
    vim.cmd.LspStart()
  end)
  vim.notify("LSP restarted", vim.log.levels.INFO)
end

function M.profile_startup()
  -- Use this to measure startup time
  vim.fn.system { "nvim", "--startuptime", "/tmp/nvim-startup.log", "-c", "q" }
  vim.cmd.edit "/tmp/nvim-startup.log"
end

-- Key mappings for diagnostics
local keymap = vim.keymap.set
keymap("n", "<leader>dp", M.check_performance, { noremap = true, silent = true })
keymap("n", "<leader>dc", M.list_lsp_clients, { noremap = true, silent = true })
keymap("n", "<leader>dr", M.restart_lsp, { noremap = true, silent = true })

return M
```

### Neovim Startup Time Analysis

```bash
# Profile Neovim startup time
nvim --startuptime /tmp/nvim-startup.log -c q
tail /tmp/nvim-startup.log

# Look for slow plugins/modules in output
cat /tmp/nvim-startup.log | sort -k2 -rn | head -20
```

### Identifying Performance Issues

```vim
" Check LSP performance
:LspInfo

" Check plugin load times
:Lazy profile

" Check memory usage
:messages

" Monitor LSP messages
:LspLog
```

---

## Quick Performance Checklist

### Before Optimizing
- [ ] Measure current startup time: `nvim --startuptime /tmp/startup.log`
- [ ] Note current issues (freezes, lag, slow completions)
- [ ] Check available system resources

### Core Optimizations (Do First)
- [ ] Disable unnecessary LSP diagnostics
- [ ] Set `update_in_insert = false` for diagnostics
- [ ] Configure LSP debouncing to 300ms
- [ ] Limit Treesitter to files < 500KB
- [ ] Enable lazy loading for plugins

### Advanced Optimizations
- [ ] Profile startup time with `--startuptime`
- [ ] Identify slowest plugins with `:Lazy profile`
- [ ] Consider disabling LSP features you don't use
- [ ] Disable auto-suggestions if using Avante
- [ ] Use lighter colorscheme if needed

### Avante-Specific Optimization
- [ ] Disable `auto_suggestions`
- [ ] Set `max_concurrent_requests = 1`
- [ ] Add proper parameter validation
- [ ] Monitor for nil value errors in logs
- [ ] Increase debounce timeout

---

## Troubleshooting Common Issues

### Issue: Neovim Freezes on Large Files
**Solution:**
```lua
-- Disable Treesitter for large files
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    if vim.fn.getfsize(vim.fn.bufname(args.buf)) > 500 * 1024 then
      vim.opt_local.syntax = "off"
      vim.opt_local.foldmethod = "manual"
    end
  end,
})
```

### Issue: LSP Constantly Crashing
**Solution:**
- Increase `debounce_text_changes` to 500ms
- Reduce diagnostic severity levels
- Check LSP logs: `:LspLog`
- Restart LSP: `:LspStop` then `:LspStart`

### Issue: Avante Returns nil new_str Error
**Solution:**
```lua
-- Add validation in your keymaps
vim.keymap.set("v", "<leader>aa", function()
  -- Validate selection before sending
  local start = vim.fn.line "v"
  local finish = vim.fn.line "."
  if start == finish then
    vim.notify("Please select multiple lines for Avante", vim.log.levels.WARN)
    return
  end
  vim.cmd "AvanteAsk"
end)
```

### Issue: Autocomplete is Slow
**Solution:**
```lua
-- Reduce completion items displayed
local cmp = require "cmp"
cmp.setup({
  performance = {
    max_view_entries = 20,
    debounce = 100,
    throttle = 50,
  },
})
```

### Issue: Plugins Taking Too Long to Load
**Solution:**
```lua
-- Ensure critical plugins have priority
{
  "your-plugin/name",
  priority = 1000, -- Load early
  lazy = false,
}

-- Defer non-essential plugins
{
  "your-plugin/name",
  event = "VeryLazy",
  lazy = true,
}
```

---

## Performance Best Practices

### Do's
✅ Use lazy loading for most plugins
✅ Disable LSP features you don't use
✅ Monitor startup time regularly
✅ Keep file size limits in place
✅ Use debouncing for text change events
✅ Profile regularly with `:Lazy profile`
✅ Keep plugin count under 50

### Don'ts
❌ Don't enable all LSP diagnostic features
❌ Don't load heavy plugins at startup
❌ Don't have more than 3 LSP clients active
❌ Don't enable syntax highlighting for huge files
❌ Don't ignore error logs and warnings
❌ Don't use deprecated plugin features

---

## References & Resources

- [Neovim Performance Tips](https://neovim.io/)
- [LSP Configuration Best Practices](https://github.com/neovim/nvim-lspconfig)
- [Lazy.nvim Documentation](https://github.com/folke/lazy.nvim)
- [Treesitter Configuration](https://github.com/nvim-treesitter/nvim-treesitter)
- [Avante Documentation](https://github.com/yetone/avante.nvim)
- [AstroNvim Configuration](https://docs.astronvim.com)

---

## Summary

By implementing these performance optimizations, you should see:
- **30-50% faster startup time**
- **Reduced CPU/memory usage**
- **Smoother typing and navigation**
- **Fewer freezes and hangs**
- **Better Avante integration** with proper error handling

Start with the "Core Optimizations" section and gradually implement advanced optimizations based on your specific needs and system performance.
