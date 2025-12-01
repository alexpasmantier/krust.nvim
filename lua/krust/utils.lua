local M = {}

--- Strip ANSI escape codes from text
---@param text string Text containing ANSI codes
---@return string Text with ANSI codes removed
function M.strip_ansi_codes(text)
  local stripped = text:gsub("\27%[[\30-\63]*[\64-\126]", "") -- CSI sequences
  stripped = stripped:gsub("\27%][^\27]*\27\\", "") -- OSC sequences
  stripped = stripped:gsub("\27[%(%)][AB012]", "") -- Character set sequences
  return stripped
end

--- Calculate maximum display width across all lines in text
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
