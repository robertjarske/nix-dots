-- Configuration and state management for i18n-helper

local M = {}

M.defaults = {
  translation_path = "",
  languages = { "en", "se", "cn" },
  current_language = "en",
  fallback_language = "en",
  virtual_text_enabled = true,
  virtual_text_prefix = " → ",
  virtual_text_highlight = "Comment",
  cache_size = 500,
  debounce_ms = 200,
  watch_files = true,
  max_file_size = 10000,
}

M.config = vim.deepcopy(M.defaults)

M.translations = {}
M.cache = nil
M.virtual_text_ns = nil
M.file_watchers = {}
M.autocmd_ids = {}
M.debounce_timers = {}

-- Single pattern: matches any quoted translation key ('TXT_123', "SETTINGS_456", etc.)
-- Covers both t('TXT_123') and t({ args: 'TXT_123' }) syntaxes
M.patterns = {
  bare_key = "['\"]([A-Z][A-Z0-9_]*_%d+)['\"]",
}

--- Auto-detect translation path from git root
---@return string|nil path
local function detect_translation_path()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if not git_root or git_root == "" then return nil end
  local path = git_root .. "/src/i18n/translation/"
  if vim.fn.isdirectory(path) == 1 then
    return path
  end
  return nil
end

---@param opts table User configuration options
---@return boolean success
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

  if M.config.translation_path == "" then
    local detected = detect_translation_path()
    if detected then
      M.config.translation_path = detected
    else
      -- Not in a project with translations — will retry on DirChanged
      return true
    end
  end

  if not vim.endswith(M.config.translation_path, "/") then
    M.config.translation_path = M.config.translation_path .. "/"
  end

  return true
end

--- Attempt to re-detect translation path (called on DirChanged)
function M.redetect_path()
  if M.config.translation_path ~= "" then return false end
  local detected = detect_translation_path()
  if detected then
    M.config.translation_path = detected
    if not vim.endswith(M.config.translation_path, "/") then
      M.config.translation_path = M.config.translation_path .. "/"
    end
    return true
  end
  return false
end

function M.get_config() return M.config end

function M.set_current_language(lang)
  if vim.tbl_contains(M.config.languages, lang) then
    M.config.current_language = lang
    return true
  end
  return false
end

function M.get_current_language() return M.config.current_language end
function M.is_virtual_text_enabled() return M.config.virtual_text_enabled end
function M.toggle_virtual_text()
  M.config.virtual_text_enabled = not M.config.virtual_text_enabled
end

function M.clear_timers()
  for _, timer in pairs(M.debounce_timers) do
    if timer then timer:stop() end
  end
  M.debounce_timers = {}
end

function M.cleanup()
  M.clear_timers()
  for _, fs_event in pairs(M.file_watchers) do
    if fs_event then fs_event:stop() end
  end
  M.file_watchers = {}
  for _, id in ipairs(M.autocmd_ids) do
    pcall(vim.api.nvim_del_autocmd, id)
  end
  M.autocmd_ids = {}
end

return M
