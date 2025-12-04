local utils = require("krust.utils")

local M = {}

local float_winnr = nil

local function close_float()
  if float_winnr and vim.api.nvim_win_is_valid(float_winnr) then
    vim.api.nvim_win_close(float_winnr, true)
    float_winnr = nil
  end
end

--- Apply ANSI highlights to buffer
---@param bufnr number Buffer number
---@param segments table[] Parsed ANSI segments
local function apply_highlights(bufnr, segments)
  -- Always redefine highlights to pick up theme changes
  utils.define_ansi_highlights()

  local line_num = 0
  local col_start = 0

  for _, segment in ipairs(segments) do
    local text = segment.text
    local hl_group = segment.hl_group

    if not hl_group then
      -- No highlight, just advance position
      for i = 1, #text do
        local byte = text:byte(i)
        if byte == 10 then -- newline
          line_num = line_num + 1
          col_start = 0
        else
          col_start = col_start + 1
        end
      end
    else
      -- Split segment by newlines and apply highlights
      local segment_lines = vim.split(text, "\n", { plain = true })
      for line_idx, line_text in ipairs(segment_lines) do
        if line_idx > 1 then
          -- Not the first line, so we crossed a newline
          line_num = line_num + 1
          col_start = 0
        end

        if #line_text > 0 then
          local col_end = col_start + #line_text
          vim.api.nvim_buf_add_highlight(bufnr, -1, hl_group, line_num, col_start, col_end)
          col_start = col_end
        end
      end
    end
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

  -- Parse ANSI codes and prepare buffer content
  local segments = utils.parse_ansi_codes(rendered)
  local stripped = utils.strip_ansi_codes(rendered)
  local lines = vim.split(stripped, "\n", { plain = true })

  -- Calculate window dimensions with wrapping
  local editor_width = vim.o.columns
  local max_width = math.floor(editor_width * 0.6) -- Use 60% of screen width
  local content_width = math.min(utils.get_max_line_width(stripped), max_width)

  -- Estimate height accounting for wrapped lines
  local estimated_height = 0
  for _, line in ipairs(lines) do
    local line_width = vim.fn.strwidth(line)
    local wrapped_lines = math.max(1, math.ceil(line_width / content_width))
    estimated_height = estimated_height + wrapped_lines
  end

  -- Cap height at reasonable maximum
  local max_height = math.floor(vim.o.lines * 0.6)
  local window_height = math.min(estimated_height, max_height)

  vim.schedule(function()
    -- Capture the original buffer number before creating the float window
    -- This is needed for autocmds to work correctly when auto_focus = true
    local orig_bufnr = vim.api.nvim_get_current_buf()

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"

    -- Calculate cursor position within the window
    local win_id = vim.api.nvim_get_current_win()
    local win_height = vim.api.nvim_win_get_height(win_id)

    -- Get the cursor's screen position relative to the window (0-indexed)
    local cursor_row = vim.fn.winline() - 1
    local cursor_col = vim.fn.wincol() - 1

    -- Position float below cursor, but ensure it fits in the window
    local float_row = cursor_row + 1
    local float_col = cursor_col

    -- Adjust if float would extend beyond window bounds vertically
    if float_row + window_height > win_height then
      -- Position above cursor, ending on the line above cursor
      float_row = math.max(0, cursor_row - window_height - 2)
    end

    local auto_focus = float_config.auto_focus or false
    local winnr = vim.api.nvim_open_win(bufnr, auto_focus, {
      relative = "win",
      win = win_id,
      width = content_width + 2,
      height = math.min(window_height, win_height),
      row = float_row,
      col = float_col,
      style = "minimal",
      border = float_config.border or "rounded",
      zindex = 50,
    })

    -- Set buffer content and apply highlights
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    apply_highlights(bufnr, segments)
    vim.bo[bufnr].modifiable = false

    -- Enable text wrapping
    vim.wo[winnr].wrap = true
    vim.wo[winnr].linebreak = true -- Wrap at word boundaries
    vim.wo[winnr].breakindent = true -- Preserve indentation when wrapping

    float_winnr = winnr

    -- Auto-close on cursor movement or mode changes in the original buffer
    local close_events = vim.api.nvim_create_augroup("KrustFloatClose", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
      group = close_events,
      buffer = orig_bufnr,
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
