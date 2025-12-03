local renderer = require("krust.renderer")

local M = {}

local lsp_patched = false

---@class KrustFloatConfig
---@field border? string Border style: "none", "single", "double", "rounded", "solid", "shadow"
---@field auto_focus? boolean Automatically focus the floating window on open (default: false)

---@class KrustConfig
---@field keymap string|false Default keymap for Rust buffers (false to disable)
---@field float_win? KrustFloatConfig Floating window configuration

local config = {
  keymap = false,
  float_win = {
    border = "rounded",
    auto_focus = false,
  },
}

---@param opts? KrustConfig
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if lsp_patched then
    return
  end
  lsp_patched = true

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
end

M.render = function()
  renderer.render(config.float_win)
end

M.get_config = function()
  return config
end

return M
