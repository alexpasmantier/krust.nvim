-- Rust Diagnostic Renderer
-- Displays rendered diagnostics from rust-analyzer in a floating window

local M = {}

-- Track the floating window so we can close it
local float_winnr = nil

--- Close the floating window if it's open
local function close_float()
  if float_winnr and vim.api.nvim_win_is_valid(float_winnr) then
    vim.api.nvim_win_close(float_winnr, true)
    float_winnr = nil
  end
end

--- Render diagnostic on current line in a floating window
function M.render()
  -- Get diagnostics on current line
  local cursor = vim.api.nvim_win_get_cursor(0)
  local diagnostics = vim.diagnostic.get(0, { lnum = cursor[1] - 1 })

  -- Find first diagnostic with rendered field
  local rendered = nil
  for _, diagnostic in ipairs(diagnostics) do
    rendered = vim.tbl_get(diagnostic, "user_data", "lsp", "data", "rendered")
    if type(rendered) == "string" then
      break
    end
  end

  if not rendered then
    vim.notify("No rendered diagnostic on current line", vim.log.levels.INFO)
    return
  end

  -- Check if diagnostic has ANSI codes
  local has_ansi = rendered:match("[\27\155]") ~= nil
  if not has_ansi then
    vim.notify(
      "krust.nvim: No ANSI codes in diagnostic. Configure rust-analyzer with colorDiagnosticOutput=true (see :help krust)",
      vim.log.levels.WARN
    )
  end

  -- Strip ANSI codes to calculate window dimensions
  local lines = vim.split(rendered:gsub("[\27\155][][()#;?%%d]*[A-PRZcf-ntqry=><~]", ""), "\n", { trimempty = true })

  vim.schedule(function()
    -- Create floating window
    local bufnr, winnr = vim.lsp.util.open_floating_preview(lines, "plaintext", {
      border = "rounded",
      max_width = math.floor(vim.o.columns * 0.8),
      max_height = math.floor(vim.o.lines * 0.8),
    })

    -- Clear buffer and open terminal to display ANSI colors
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    vim.bo[bufnr].modifiable = false

    -- Open terminal and send content with proper line endings
    local chanid = vim.api.nvim_open_term(bufnr, {})
    local content = rendered:gsub("\n", "\r\n")
    vim.api.nvim_chan_send(chanid, vim.trim(content))

    -- Exit terminal mode when entering the window
    vim.api.nvim_create_autocmd("WinEnter", {
      callback = function()
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes(
            [[<C-\><C-n>]] .. "<cmd>lua vim.api.nvim_win_set_cursor(" .. winnr .. ",{1,0})<CR>",
            true,
            false,
            true
          ),
          "n",
          true
        )
      end,
      buffer = bufnr,
    })

    -- Save window reference and set close keymaps
    float_winnr = winnr
    vim.keymap.set("n", "q", close_float, { buffer = bufnr, silent = true })
    vim.keymap.set("n", "<Esc>", close_float, { buffer = bufnr, silent = true })
  end)
end

return M
