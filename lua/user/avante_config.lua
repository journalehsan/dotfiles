-- Avante.nvim configuration with performance fixes
require("avante").setup({
  -- Provider configuration (e.g., OpenAI, Claude, etc.)
  provider = "openai",

  -- Disable auto-suggestions to prevent unnecessary API calls
  auto_suggestions = {
    enabled = false,
  },

  -- Add validation for tool parameters
  tool_validation = {
    enabled = true,
    required_fields = {
      str_replace = { "old_str", "new_str", "file_path" },
    },
  },

  -- Performance settings
  performance = {
    request_timeout = 30000, -- 30 seconds timeout for API calls
    max_concurrent_requests = 1, -- Limit to 1 concurrent request
    debounce_ms = 500, -- Debouncing API calls
  },

  -- Additional behavior settings
  behaviour = {
    auto_focus_on_tool_window = true,
    auto_apply_diff_after_generation = false,
  },

  -- UI and window settings
  windows = {
    wrap = true,
    width = 30,
    sidebar_header = {
      align = "center",
      rounded = true,
    },
  },
})

