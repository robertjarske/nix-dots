-- Custom Telescope picker for searching translations

local config = require("i18n-helper.config")
local translation = require("i18n-helper.translation")
local M = {}

--- Truncate text to fit column width
---@param text string Text to truncate
---@param width number Column width
---@return string truncated
local function truncate(text, width)
  if not text then
    return string.rep(" ", width)
  end

  if #text <= width then
    return text .. string.rep(" ", width - #text)
  end

  return text:sub(1, width - 3) .. "..."
end

--- Format entry for display (three columns)
---@param key string Translation key
---@return string display
function M.format_entry(key)
  local translations = translation.get_all_translations(key)

  -- Column widths
  local key_width = 20
  local en_width = 30
  local se_width = 30
  local cn_width = 30

  -- Truncate and pad
  local key_str = truncate(key, key_width)
  local en_str = truncate(translations.en or "[MISSING]", en_width)
  local se_str = truncate(translations.se or "[MISSING]", se_width)
  local cn_str = truncate(translations.cn or "[MISSING]", cn_width)

  -- Format with separators
  return string.format("%s │ %s │ %s │ %s", key_str, en_str, se_str, cn_str)
end

--- Make ordinal string for searching (all text concatenated)
---@param key string Translation key
---@return string ordinal
function M.make_ordinal(key)
  local translations = translation.get_all_translations(key)
  local parts = { key }

  for _, lang in ipairs(config.get_config().languages) do
    if translations[lang] then
      table.insert(parts, translations[lang])
    end
  end

  return table.concat(parts, " ")
end

--- Get TXT code under cursor
---@return string|nil key, number|nil start_col, number|nil end_col
local function get_txt_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- Pattern to match TXT codes
  local pattern = "[A-Z_]+[A-Z0-9_]*"

  local start_col = 1
  while start_col <= #line do
    local match_start, match_end = line:find(pattern, start_col)
    if not match_start then break end

    -- Check if cursor is within this match
    if col >= match_start and col <= match_end then
      local key = line:sub(match_start, match_end)
      return key, match_start, match_end
    end

    start_col = match_end + 1
  end

  return nil, nil, nil
end

--- Search translations with Telescope
---@param opts table|nil Telescope options
function M.search_translations(opts)
  opts = opts or {}

  -- Check if Telescope is available
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("i18n: Telescope not found", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- Capture TXT code under cursor for replacement
  local txt_under_cursor, start_col, end_col = get_txt_under_cursor()
  local should_replace = txt_under_cursor ~= nil
  local bufnr = vim.api.nvim_get_current_buf()
  local linenr = vim.api.nvim_win_get_cursor(0)[1]

  -- Get all translation keys
  local keys = translation.get_all_keys()
  if #keys == 0 then
    vim.notify("i18n: No translations loaded", vim.log.levels.WARN)
    return
  end

  -- Build entries
  local entries = {}
  for _, key in ipairs(keys) do
    local translations = translation.get_all_translations(key)
    table.insert(entries, {
      value = key,
      display = M.format_entry(key),
      ordinal = M.make_ordinal(key),
      en = translations.en,
      se = translations.se,
      cn = translations.cn,
    })
  end

  -- Create picker
  pickers
    .new(opts, {
      prompt_title = "i18n Translations",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return entry
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- Default action: replace TXT under cursor or insert at cursor
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection then
            if should_replace then
              -- Replace the TXT code under cursor
              local line = vim.api.nvim_buf_get_lines(bufnr, linenr - 1, linenr, false)[1]
              local new_line = line:sub(1, start_col - 1) .. selection.value .. line:sub(end_col + 1)
              vim.api.nvim_buf_set_lines(bufnr, linenr - 1, linenr, false, { new_line })

              -- Move cursor to end of replacement
              vim.api.nvim_win_set_cursor(0, { linenr, start_col + #selection.value - 1 })
            else
              -- Insert at cursor position
              vim.api.nvim_put({ selection.value }, "", true, true)
            end
          end
        end)

        -- Additional mappings
        map("i", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            -- Yank key to clipboard
            vim.fn.setreg("+", selection.value)
            vim.notify(string.format("i18n: Yanked '%s' to clipboard", selection.value), vim.log.levels.INFO)
          end
        end)

        map("i", "<C-e>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.en then
            -- Insert English translation
            vim.api.nvim_put({ selection.en }, "", true, true)
          end
        end)

        map("i", "<C-s>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.se then
            -- Insert Swedish translation
            vim.api.nvim_put({ selection.se }, "", true, true)
          end
        end)

        map("i", "<C-c>", function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.cn then
            -- Insert Chinese translation
            vim.api.nvim_put({ selection.cn }, "", true, true)
          end
        end)

        return true
      end,
      previewer = false, -- Disable previewer for cleaner display
    })
    :find()
end

return M
