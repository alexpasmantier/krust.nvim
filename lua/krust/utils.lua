local M = {}

-- the reasoning here is that rust analyzer only outputs pretty standard ANSI stuff
-- so we don't need a full blown parser

local ANSI_TO_TERM_COLOR = {
  [30] = 0, -- black
  [31] = 1, -- red
  [32] = 2, -- green
  [33] = 3, -- yellow
  [34] = 4, -- blue
  [35] = 5, -- magenta
  [36] = 6, -- cyan
  [37] = 7, -- white
  -- Bright colors
  [90] = 8, -- bright black (gray)
  [91] = 9, -- bright red
  [92] = 10, -- bright green
  [93] = 11, -- bright yellow
  [94] = 12, -- bright blue
  [95] = 13, -- bright magenta
  [96] = 14, -- bright cyan
  [97] = 15, -- bright white
}

---@param index number Terminal color index (0-15)
---@return string? Hex color or nil
local function get_terminal_color(index)
  local color = vim.g["terminal_color_" .. index]
  if color then
    return color
  end

  -- otherwise try the highlight group
  local term_hl = vim.api.nvim_get_hl(0, { name = "Terminal" })
  if term_hl and term_hl.fg then
    return string.format("#%06x", term_hl.fg)
  end

  return nil
end

function M.define_ansi_highlights()
  for code, term_idx in pairs(ANSI_TO_TERM_COLOR) do
    local hl_name = string.format("KrustAnsiFg%d", code)
    local color = get_terminal_color(term_idx)

    if color then
      vim.api.nvim_set_hl(0, hl_name, { fg = color })
    else
      -- otherwise link to standard highlight groups
      local link_map = {
        [31] = "ErrorMsg", -- red
        [32] = "String", -- green
        [33] = "WarningMsg", -- yellow
        [34] = "Function", -- blue
        [91] = "ErrorMsg", -- bright red
        [92] = "String", -- bright green
        [93] = "WarningMsg", -- bright yellow
        [94] = "Function", -- bright blue
      }
      if link_map[code] then
        vim.api.nvim_set_hl(0, hl_name, { link = link_map[code] })
      end
    end
  end

  vim.api.nvim_set_hl(0, "KrustAnsiBold", { bold = true })

  -- combined highlights
  for code, term_idx in pairs(ANSI_TO_TERM_COLOR) do
    local hl_name = string.format("KrustAnsiFg%dBold", code)
    local color = get_terminal_color(term_idx)

    if color then
      vim.api.nvim_set_hl(0, hl_name, { fg = color, bold = true })
    else
      local link_map = {
        [31] = "ErrorMsg",
        [32] = "String",
        [33] = "WarningMsg",
        [34] = "Function",
        [91] = "ErrorMsg",
        [92] = "String",
        [93] = "WarningMsg",
        [94] = "Function",
      }
      if link_map[code] then
        vim.api.nvim_set_hl(0, hl_name, { link = link_map[code], bold = true })
      else
        vim.api.nvim_set_hl(0, hl_name, { bold = true })
      end
    end
  end
end

---@param text string Text containing ANSI codes
---@return table[] Array of segments: { text = string, hl_group = string? }
function M.parse_ansi_codes(text)
  local segments = {}
  local pos = 1
  local current_hl = { fg = nil, bold = false }

  local function get_hl_group()
    if not current_hl.fg and not current_hl.bold then
      return nil
    end

    if current_hl.fg and current_hl.bold then
      return string.format("KrustAnsiFg%dBold", current_hl.fg)
    elseif current_hl.fg then
      return string.format("KrustAnsiFg%d", current_hl.fg)
    elseif current_hl.bold then
      return "KrustAnsiBold"
    end
  end

  while pos <= #text do
    -- Look for ESC[...m
    local esc_start, esc_end, codes_str = text:find("\27%[([%d;]*)m", pos)

    if esc_start then
      -- add any text before the escape sequence
      if esc_start > pos then
        local segment_text = text:sub(pos, esc_start - 1)
        table.insert(segments, { text = segment_text, hl_group = get_hl_group() })
      end

      -- parse the codes
      if codes_str == "" or codes_str == "0" then
        current_hl = { fg = nil, bold = false }
      else
        local codes = vim.split(codes_str, ";", { plain = true })
        local i = 1
        while i <= #codes do
          local code = tonumber(codes[i])

          if code == 0 then
            -- Reset
            current_hl = { fg = nil, bold = false }
            i = i + 1
          elseif code == 1 then
            -- Bold
            current_hl.bold = true
            i = i + 1
          elseif code == 22 then
            -- Normal intensity (turn off bold)
            current_hl.bold = false
            i = i + 1
          elseif code == 38 or code == 48 then
            -- Extended color format: 38;5;N (foreground) or 48;5;N (background)
            if i + 2 <= #codes and tonumber(codes[i + 1]) == 5 then
              local color_idx = tonumber(codes[i + 2])
              if code == 38 then
                -- Foreground color - map 256-color index to our palette
                if color_idx >= 0 and color_idx <= 15 then
                  -- Map to basic ANSI codes: 0-7 -> 30-37, 8-15 -> 90-97
                  if color_idx <= 7 then
                    current_hl.fg = 30 + color_idx
                  else
                    current_hl.fg = 90 + (color_idx - 8)
                  end
                end
              end
              i = i + 3
            else
              i = i + 1
            end
          elseif ANSI_TO_TERM_COLOR[code] then
            -- Basic foreground color (30-37, 90-97)
            current_hl.fg = code
            i = i + 1
          else
            i = i + 1
          end
        end
      end

      pos = esc_end + 1
    else
      -- No more escape sequences, add remaining text
      local segment_text = text:sub(pos)
      if #segment_text > 0 then
        table.insert(segments, { text = segment_text, hl_group = get_hl_group() })
      end
      break
    end
  end

  return segments
end

---@param text string Text containing ANSI codes
---@return string Text with ANSI codes removed
function M.strip_ansi_codes(text)
  local stripped = text:gsub("\27%[[\30-\63]*[\64-\126]", "") -- CSI sequences
  stripped = stripped:gsub("\27%][^\27]*\27\\", "") -- OSC sequences
  stripped = stripped:gsub("\27[%(%)][AB012]", "") -- Character set sequences
  return stripped
end

---@param text string Text to measure (should have ANSI codes stripped)
---@return number Maximum display width of any line
function M.get_max_line_width(text)
  local lines = vim.split(text, "\n", { trimempty = true })
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, vim.fn.strwidth(line))
  end
  return max_width
end

return M
