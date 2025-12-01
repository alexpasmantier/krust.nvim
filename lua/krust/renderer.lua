local utils = require("krust.utils")

local M = {}

local float_winnr = nil

local function close_float()
  if float_winnr and vim.api.nvim_win_is_valid(float_winnr) then
    vim.api.nvim_win_close(float_winnr, true)
    float_winnr = nil
  end
end

function M.render()
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
    local win_width = math.min(content_width + 4, math.floor(vim.o.columns * 0.9))
    local win_height = math.min(#lines, math.floor(vim.o.lines * 0.8))

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"

    local winnr = vim.api.nvim_open_win(bufnr, false, {
      relative = "cursor",
      width = win_width,
      height = win_height,
      row = 1,
      col = 0,
      style = "minimal",
      border = "rounded",
      zindex = 50,
    })

    local chanid = vim.api.nvim_open_term(bufnr, { force_crlf = true })
    vim.api.nvim_chan_send(chanid, rendered)

    float_winnr = winnr

    -- Auto-close on cursor movement or mode changes in the original buffer
    local close_events = vim.api.nvim_create_augroup("KrustFloatClose", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter" }, {
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
