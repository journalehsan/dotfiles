-- Global LSP settings for performance optimization
local util = require "lspconfig.util"

-- Define capabilities with reduced features for better performance
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.synchronization.didSave = true
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- Set debounce time to reduce frequent updates
local debounce_ms = 300

-- Configure diagnostics to reduce noise and improve performance
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

-- Handler to limit diagnostics only for active buffers
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
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

