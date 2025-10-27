# Avante Quick Start & Performance Optimization

## Installation & Setup

### 1. Install Avante.nvim
```bash
# Using Lazy.nvim (already configured in the performance guide)
cd ~/.config/nvim
# Add avante.nvim to your plugins
```

### 2. Set Up API Keys
```bash
# For OpenAI
export OPENAI_API_KEY="your-key-here"

# For Claude (Anthropic)
export ANTHROPIC_API_KEY="your-key-here"

# For Gemini
export GEMINI_API_KEY="your-key-here"
```

## Quick Configuration Template

Create this file: `~/.config/nvim/lua/user/plugins/avante.lua`

```lua
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
        opts = { file_types = { "Avante" } },
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

      -- CRITICAL: Disable auto-suggestions to prevent freezes
      auto_suggestions_provider = "openai",
      auto_suggestions = {
        enabled = false,
      },

      -- Performance settings
      behaviour = {
        auto_focus_on_tool_window = true,
        auto_apply_diff_after_generation = false,
      },

      windows = {
        wrap = true,
        width = 30,
        sidebar_header = {
          align = "center",
          rounded = true,
        },
      },
    },
  },
}
```

## Essential Keymaps

Add to `~/.config/nvim/lua/user/keymaps.lua`:

```lua
-- Avante keymaps
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Visual mode - Ask Avante
keymap("v", "<leader>aa", ":AvanteAsk<CR>", opts)

-- Visual mode - Edit with Avante
keymap("v", "<leader>ae", ":AvanteEdit<CR>", opts)

-- Normal mode - Toggle sidebar
keymap("n", "<leader>at", ":AvanteToggle<CR>", opts)

-- Visual mode - Refactor code
keymap("v", "<leader>ar", ":AvanteRefactor<CR>", opts)
```

## Usage Examples

### 1. Ask Avante a Question
```
1. Select text or leave empty for context
2. Press <leader>aa
3. Type your question
4. Wait for response
```

### 2. Edit Code
```
1. Select code to edit
2. Press <leader>ae
3. Describe the changes you want
4. Accept or reject the diff
```

### 3. Refactor Code
```
1. Select code to refactor
2. Press <leader>ar
3. Avante will suggest refactoring
4. Review and apply changes
```

## Fixing Common Issues

### Issue: "nil new_str" Error
**Cause:** LLM returned incomplete tool parameters
**Fix:** Make sure to:
- Select valid code regions
- Give clear, detailed instructions
- Use concise prompts
- Avoid ambiguous selections

### Issue: Avante is Freezing
**Fix:** Ensure these settings:
```lua
auto_suggestions = { enabled = false }
max_concurrent_requests = 1
request_timeout = 30000
```

### Issue: Slow Responses
**Fix:**
- Check your API rate limits
- Verify internet connection
- Reduce `max_tokens` value
- Try a faster model (e.g., gpt-4-turbo instead of gpt-4)

## Performance Tips

1. **Don't enable auto-suggestions** - They cause constant API calls
2. **Use keyboard shortcuts** - Faster than clicking
3. **Keep selections small** - Easier for LLM to process
4. **Use clear prompts** - Reduces back-and-forth
5. **Review diffs carefully** - Check generated code before applying

## Advanced Configuration

### Using Different LLM Providers

**Claude (Anthropic):**
```lua
provider = "claude",
claude = {
  model = "claude-3-5-sonnet-20241022",
  timeout = 30000,
},
```

**Local Models (Ollama):**
```lua
provider = "openai", -- Use OpenAI-compatible endpoint
openai = {
  api_key = "not-needed",
  base_url = "http://localhost:11434/v1",
  model = "mistral",
},
```

### Custom Tool Validation

Add to `~/.config/nvim/lua/user/avante_hooks.lua`:

```lua
-- Hook into tool execution for validation
local M = {}

function M.setup()
  local avante = require("avante")

  -- Add custom validation
  vim.api.nvim_create_user_command("AvanteAskValidated", function()
    local mode = vim.api.nvim_get_mode().mode
    if mode ~= "v" and mode ~= "V" then
      vim.notify("Please select text first!", vim.log.levels.WARN)
      return
    end
    vim.cmd "AvanteAsk"
  end, {})
end

return M
```

## Monitoring Performance

Check Avante's resource usage:

```vim
" List all Avante buffers
:buffers

" Check Avante logs
:AvanteLog
```

Monitor with commands:
```bash
# Watch Neovim memory usage
watch -n 1 'ps aux | grep nvim'

# Monitor API calls
tail -f ~/.cache/nvim/avante.log
```

## Best Practices

✅ **Do:**
- Use Avante for code review, not generation
- Break large files into smaller chunks
- Use specific, detailed prompts
- Review all generated code changes
- Keep Avante sidebar closed when not in use
- Monitor your API usage and costs

❌ **Don't:**
- Enable auto-suggestions
- Send the entire codebase as context
- Use vague prompts
- Apply changes without reviewing
- Run multiple Avante operations concurrently
- Ignore error messages in logs

## Troubleshooting Checklist

- [ ] API key is set correctly
- [ ] Internet connection is stable
- [ ] LSP is not frozen (check `:LspInfo`)
- [ ] No other heavy operations running
- [ ] Avante auto-suggestions are disabled
- [ ] Plugin is up to date (run `:Lazy update`)
- [ ] Neovim is latest stable version

## Next Steps

1. Implement LSP performance settings from the main guide
2. Enable proper Treesitter configuration
3. Set up plugin lazy-loading
4. Monitor startup time with `nvim --startuptime`
5. Gradually enable advanced Avante features as needed

For comprehensive performance optimization, see: `NEOVIM_AVANTE_PERFORMANCE_GUIDE.md`

