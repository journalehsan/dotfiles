return {
  {
    "Mofiqul/dracula.nvim",
    lazy = false,  -- Load immediately
    priority = 1000,  -- Load before other plugins
    config = function()
      -- Configure Dracula theme
      local dracula = require("dracula")
      
      dracula.setup({
        -- Show the background color in comment line
        show_end_of_line = false,
        -- use transparent background
        transparent_bg = false,
        -- set custom lualine background color
        lualine_bg_color = "#44475a",
        -- set italic comment
        italic_comment = true,
        -- overrides the default highlights with table see `:h synIDattr`
        overrides = {},
        -- You can use overrides as function too
        -- overrides = function ()
        --   return {
        --     NonText = { fg = dracula.colors().white },
        --     Normal = { fg = dracula.colors().white }
        --   }
        -- end,
      })
      
      -- Apply the colorscheme
      vim.cmd("colorscheme dracula")
    end,
  },
}
