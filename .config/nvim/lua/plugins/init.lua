return {
  -- GitHub Copilot with cmp source.
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      require("copilot_cmp").setup()

      -- Add copilot source if NvChad defaults omit it.
      local cmp = require("cmp")
      local config = cmp.get_config()
      config.sources = config.sources or {}
      table.insert(config.sources, 1, { name = "copilot", group_index = 2 })
      cmp.setup(config)
    end,
  },

  -- Avante AI assistant.
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "stevearc/dressing.nvim",
    },
    opts = {},
  },
}
