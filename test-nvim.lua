-- Test file for Neovim configuration
-- Open with: nvim test-nvim.lua

local function greet(name)
  print("Hello, " .. name .. "! 👋")
  print("Your Neovim config is working great! 🚀")
end

-- Test LSP, completion, and syntax highlighting
greet("Ehsan")

-- Test table
local config = {
  editor = "neovim",
  theme = "catppuccin",
  plugins = {"lazy", "treesitter", "lsp", "avante"},
  performance = "optimized"
}

print(vim.inspect(config))
