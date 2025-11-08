return {
  {
    "yetone/avante.nvim",
    -- Build from source for optimal performance
    build = vim.fn.has("win32") ~= 0
      and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    event = "VeryLazy",
    version = false, -- Never set this to "*"!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      -- Project-specific instructions
      instructions_file = "avante.md",
      -- Default provider
      provider = "copilot",
      -- Multiple providers configuration
      providers = {
        copilot = {
          model = "gpt-4o",
          timeout = 30000,
          proxy = nil,
          allow_insecure = false,
          max_tokens = 4096,
        },
        amp = {
          __inherited_from = "openai",  -- Inherit from OpenAI provider
          api_key_name = "",            -- AMP doesn't use API key, handled by CLI
          endpoint = "http://localhost:8000/v1",  -- Default local endpoint, adjust if needed
          model = "default",
          timeout = 30000,
          proxy = nil,
          allow_insecure = true,  -- Allow for local development
        },
        claude = {
          __inherited_from = "openai",  -- Claude uses OpenAI-compatible API
          api_key_name = "ANTHROPIC_API_KEY",
          endpoint = "https://api.anthropic.com",
          model = "claude-sonnet-4-20250514",
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
        moonshot = {
          __inherited_from = "openai",  -- Moonshot uses OpenAI-compatible API
          api_key_name = "MOONSHOT_API_KEY",
          endpoint = "https://api.moonshot.ai/v1",
          model = "kimi-k2-0711-preview",
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 32768,
          },
        },
      },
      -- Behavior settings
      windows = {
        position = "right",
        width = 40,
      },
      behaviour = {
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        support_paste_from_clipboard = false,
        minimize_diff = "cursorline",
      },
      -- Stream settings
      stream = true,
      -- File type support
      file_types = {
        ignore_patterns = { "^git ", ".git/" },
        exclude = { "markdown" },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- Optional but recommended dependencies
      "nvim-mini/mini.pick",           -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp",              -- autocompletion for avante commands
      "ibhagwan/fzf-lua",              -- for file_selector provider fzf
      "stevearc/dressing.nvim",        -- for input provider dressing
      "folke/snacks.nvim",             -- for input provider snacks
      "nvim-tree/nvim-web-devicons",   -- icons
      "zbirenbaum/copilot.lua",        -- for providers='copilot'
      {
        -- Image pasting support
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Markdown rendering
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    config = function(_, opts)
      require("avante").setup(opts)

      -- Store current provider state
      local current_provider = opts.provider or "copilot"
      
      -- Provider status display function
      local function get_provider_status()
        return "🤖 Provider: " .. string.upper(current_provider)
      end

      -- Function to switch providers
      local function switch_provider(provider_name)
        local valid_providers = { "copilot", "amp", "claude", "moonshot" }
        if not vim.tbl_contains(valid_providers, provider_name) then
          vim.notify("Invalid provider: " .. provider_name, vim.log.levels.WARN)
          return
        end
        current_provider = provider_name
        vim.notify("Switched to provider: " .. provider_name, vim.log.levels.INFO)
      end

      -- Key mappings for Avante
      vim.keymap.set("n", "<leader>aa", "<cmd>Avante<cr>", { noremap = true, silent = true, desc = "Open Avante" })
      vim.keymap.set("n", "<leader>ac", "<cmd>AvanteChat<cr>", { noremap = true, silent = true, desc = "Chat with Avante" })
      vim.keymap.set("n", "<leader>ae", function()
        require("avante.api").ask({ type = "explain" })
      end, { noremap = true, silent = true, desc = "Explain code" })
      vim.keymap.set("n", "<leader>ar", function()
        require("avante.api").ask({ type = "refactor" })
      end, { noremap = true, silent = true, desc = "Refactor code" })
      vim.keymap.set("v", "<leader>ac", "<cmd>AvanteChat<cr>", { noremap = true, silent = true, desc = "Chat with selection" })
      
      -- Provider switching keymaps
      vim.keymap.set("n", "<leader>apc", function()
        switch_provider("copilot")
      end, { noremap = true, silent = true, desc = "Switch to Copilot" })
      
      vim.keymap.set("n", "<leader>apa", function()
        switch_provider("amp")
      end, { noremap = true, silent = true, desc = "Switch to AMP" })
      
      vim.keymap.set("n", "<leader>apk", function()
        switch_provider("claude")
      end, { noremap = true, silent = true, desc = "Switch to Claude" })
      
      vim.keymap.set("n", "<leader>apm", function()
        switch_provider("moonshot")
      end, { noremap = true, silent = true, desc = "Switch to Moonshot" })
      
      vim.keymap.set("n", "<leader>aps", function()
        vim.notify(get_provider_status(), vim.log.levels.INFO)
      end, { noremap = true, silent = true, desc = "Show provider status" })
    end,
  },
}