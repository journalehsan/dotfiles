-- Treesitter performance configuration
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

  -- Enable syntax highlighting, but disable for files over 100 KB
  highlight = {
    enable = true,
    disable = function(lang, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end

      -- Disable for specific file types
      return vim.tbl_contains({
        "sql",
        "csv",
        "log",
      }, lang)
    end,
    additional_vim_regex_highlighting = false,
  },

  -- Incremental selection for better navigation
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },

  -- Disable rainbow brackets as they can be CPU-intensive
  rainbow = {
    enable = false,
  },

  -- Enable indentation module
  indent = {
    enable = true,
  },
})

-- Auto-disable Treesitter for very large files
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

