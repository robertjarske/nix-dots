-- Translation file loading and parsing

local config = require("i18n-helper.config")
local M = {}

--- Parse JSON file with error handling
---@param filepath string Path to JSON file
---@return table|nil, string|nil data, error
function M.parse_json_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil, "Cannot open file: " .. filepath
  end

  local content = file:read("*all")
  file:close()

  if not content or content == "" then
    return nil, "File is empty: " .. filepath
  end

  local ok, result = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil, string.format("Invalid JSON in %s: %s", filepath, result)
  end

  return result, nil
end

--- Validate translation key format
---@param key string Translation key
---@return boolean
function M.validate_translation_key(key)
  -- Valid patterns: TXT_123, SETTING_123, P123, TXT_IRELAND, "TXT_NEW CALEDONIA" etc.
  -- Allow keys with spaces (some legacy keys have them)
  return key:match("^[A-Z_0-9 ]+$") ~= nil
end

--- Load single language file
---@param lang string Language code (en, se, cn)
---@return boolean success
function M.load_language(lang)
  local cfg = config.get_config()
  local filepath = cfg.translation_path .. lang .. ".json"

  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify(
      string.format("i18n: Translation file not found: %s", filepath),
      vim.log.levels.WARN
    )
    config.translations[lang] = {}
    return false
  end

  -- Parse JSON
  local data, err = M.parse_json_file(filepath)
  if err then
    vim.notify(string.format("i18n: %s", err), vim.log.levels.ERROR)
    config.translations[lang] = {}
    return false
  end

  -- Store translations (skip validation to avoid noise)
  config.translations[lang] = data

  return true
end

--- Load all translation files
---@return boolean success
function M.load_all_translations()
  local cfg = config.get_config()
  local success = true

  -- Don't spam on startup
  for _, lang in ipairs(cfg.languages) do
    local ok = M.load_language(lang)
    success = success and ok
  end

  -- Only notify on failure
  if not success then
    vim.notify("i18n: Some translations failed to load", vim.log.levels.WARN)
  end

  return success
end

--- Get translation for a key
---@param key string Translation key
---@param lang string|nil Language code (defaults to current language)
---@return string translation
function M.get_translation(key, lang)
  lang = lang or config.get_current_language()
  local cfg = config.get_config()

  -- Try current language
  local translation = config.translations[lang] and config.translations[lang][key]
  if translation then
    return translation
  end

  -- Try fallback language
  if lang ~= cfg.fallback_language then
    translation = config.translations[cfg.fallback_language]
      and config.translations[cfg.fallback_language][key]
    if translation then
      return translation
    end
  end

  -- Return key with [MISSING] indicator
  return key .. " [MISSING]"
end

--- Get translations for a key in all languages
---@param key string Translation key
---@return table translations {en="...", se="...", cn="..."}
function M.get_all_translations(key)
  local result = {}
  for _, lang in ipairs(config.get_config().languages) do
    result[lang] = config.translations[lang] and config.translations[lang][key]
  end
  return result
end

--- Get all translation keys
---@return table keys Array of all translation keys
function M.get_all_keys()
  local keys_set = {}
  local cfg = config.get_config()

  -- Collect unique keys from all languages
  for _, lang in ipairs(cfg.languages) do
    if config.translations[lang] then
      for key, _ in pairs(config.translations[lang]) do
        keys_set[key] = true
      end
    end
  end

  -- Convert set to array
  local keys = {}
  for key, _ in pairs(keys_set) do
    table.insert(keys, key)
  end

  -- Sort alphabetically
  table.sort(keys)

  return keys
end

--- Find missing translations for a language
---@param lang string Language code
---@return table missing_keys Array of keys missing in this language
function M.get_missing_keys(lang)
  local all_keys = M.get_all_keys()
  local missing = {}

  for _, key in ipairs(all_keys) do
    if not config.translations[lang] or not config.translations[lang][key] then
      table.insert(missing, key)
    end
  end

  return missing
end

return M
