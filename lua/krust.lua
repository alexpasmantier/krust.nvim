local renderer = require("krust.renderer")

local M = {}

local setup_done = false

---@class KrustConfig
---@field keymap string|false Default keymap for Rust buffers (false to disable)

local config = {
  keymap = "<leader>k",
}

---@param opts? KrustConfig
M.setup = function(opts)
  if setup_done then
    return
  end
  setup_done = true

  config = vim.tbl_deep_extend("force", config, opts or {})

  local original_start = vim.lsp.start
  vim.lsp.start = function(config, opts)
    if config.name == "rust_analyzer" or (config.cmd and config.cmd[1] and config.cmd[1]:match("rust[-_]analyzer")) then
      config.capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities()
      config.capabilities.experimental = config.capabilities.experimental or {}
      if not config.capabilities.experimental.colorDiagnosticOutput then
        config.capabilities.experimental.colorDiagnosticOutput = true
      end
    end
    return original_start(config, opts)
  end

  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok and lspconfig.rust_analyzer then
    local original_setup = lspconfig.rust_analyzer.setup
    lspconfig.rust_analyzer.setup = function(config)
      config = config or {}
      config.capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities()
      config.capabilities.experimental = config.capabilities.experimental or {}
      if not config.capabilities.experimental.colorDiagnosticOutput then
        config.capabilities.experimental.colorDiagnosticOutput = true
      end
      return original_setup(config)
    end
  end
end

M.render = function()
  renderer.render()
end

M.get_config = function()
  return config
end

return M
