local utils = require("krust.utils")

local M = {}

local float_winnr = nil

local function close_float()
  if float_winnr and vim.api.nvim_win_is_valid(float_winnr) then
    vim.api.nvim_win_close(float_winnr, true)
    float_winnr = nil
  end
end

---@param float_config? table Floating window configuration
function M.render(float_config)
  float_config = float_config or {}

  -- If floating window is already open, focus it on second press
  if float_winnr and vim.api.nvim_win_is_valid(float_winnr) then
    local current_win = vim.api.nvim_get_current_win()
    if current_win ~= float_winnr then
      vim.api.nvim_set_current_win(float_winnr)
      return
    end
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local diagnostics = vim.diagnostic.get(0, { lnum = cursor[1] - 1 })

  local rendered = nil
  for _, diagnostic in ipairs(diagnostics) do
    rendered = vim.tbl_get(diagnostic, "user_data", "lsp", "data", "rendered")
    if type(rendered) == "string" then
      break
    end
  end

  -- fallback to default diagnostics
  if not rendered then
    vim.diagnostic.open_float(nil, { focus = true })
    return
  end

  local stripped = utils.strip_ansi_codes(rendered)
  local lines = vim.split(stripped, "\n", { plain = true })
  local content_width = utils.get_max_line_width(stripped)

  vim.schedule(function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"

    local auto_focus = float_config.auto_focus or false
    local winnr = vim.api.nvim_open_win(bufnr, auto_focus, {
      relative = "cursor",
      width = content_width + 2,
      height = #lines,
      row = 1,
      col = 0,
      style = "minimal",
      border = float_config.border or "rounded",
      zindex = 50,
    })

    local chanid = vim.api.nvim_open_term(bufnr, { force_crlf = true })
    vim.api.nvim_chan_send(chanid, rendered)
    vim.bo[bufnr].modifiable = false

    float_winnr = winnr

    -- Auto-close on cursor movement or mode changes in the original buffer
    local close_events = vim.api.nvim_create_augroup("KrustFloatClose", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
      group = close_events,
      buffer = 0,
      callback = close_float,
      once = false,
    })

    -- Also close when buffer is hidden
    vim.api.nvim_create_autocmd("BufHidden", {
      buffer = bufnr,
      callback = close_float,
      once = true,
    })

    -- Keymaps to close the floating window when focused
    vim.keymap.set("n", "q", close_float, { buffer = bufnr, silent = true })
    vim.keymap.set("n", "<Esc>", close_float, { buffer = bufnr, silent = true })
  end)
end

return M
