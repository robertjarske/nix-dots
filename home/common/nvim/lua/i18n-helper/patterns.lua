-- Pattern detection for translation keys in code

local config = require("i18n-helper.config")
local M = {}

--- Quick pre-filter: check if line might contain a quoted translation key
---@param line string
---@return boolean
function M.line_might_have_translation(line)
  return line:match("['\"][A-Z]") ~= nil
end

--- Find all translation keys in a single line
--- Returns matches with end_col for inline extmark positioning
---@param line string
---@param linenr number Line number (1-indexed)
---@return table matches Array of {key, col, end_col, linenr}
function M.find_translation_keys_in_line(line, linenr)
  if not M.line_might_have_translation(line) then
    return {}
  end

  local matches = {}
  local pattern = config.patterns.bare_key
  local start_pos = 1

  while true do
    local match_start, match_end, key = line:find(pattern, start_pos)
    if not match_start then break end

    table.insert(matches, {
      key = key,
      col = match_start,
      -- match_end is 1-indexed inclusive; as 0-indexed it equals match_end
      -- which places the extmark right after the closing quote
      end_col = match_end,
      linenr = linenr,
    })

    start_pos = match_end + 1
  end

  return matches
end

---@param bufnr number
---@return table
function M.find_translation_keys_in_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local all_matches = {}
  for linenr, line in ipairs(lines) do
    for _, match in ipairs(M.find_translation_keys_in_line(line, linenr)) do
      table.insert(all_matches, match)
    end
  end
  return all_matches
end

---@param bufnr number
---@param start_line number
---@param end_line number
---@return table
function M.find_translation_keys_in_range(bufnr, start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local all_matches = {}
  for i, line in ipairs(lines) do
    local linenr = start_line + i - 1
    for _, match in ipairs(M.find_translation_keys_in_line(line, linenr)) do
      table.insert(all_matches, match)
    end
  end
  return all_matches
end

---@param matches table
---@return table grouped {[linenr] = {match1, match2, ...}}
function M.group_by_line(matches)
  local grouped = {}
  for _, match in ipairs(matches) do
    if not grouped[match.linenr] then grouped[match.linenr] = {} end
    table.insert(grouped[match.linenr], match)
  end
  return grouped
end

return M
