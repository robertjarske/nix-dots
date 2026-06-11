-- File watching for automatic translation reloading

local config = require("i18n-helper.config")
local translation = require("i18n-helper.translation")
local M = {}

local reload_timers = {}

function M.on_file_change(filepath, lang)
  local ok = translation.load_language(lang)
  if ok then
    if config.cache then config.cache:clear_language(lang) end
    local vt = require("i18n-helper.virtual_text")
    vt.refresh_all_buffers()
    vim.notify(string.format("i18n: Reloaded '%s'", lang), vim.log.levels.INFO)
  else
    vim.notify(string.format("i18n: Failed to reload '%s'", lang), vim.log.levels.ERROR)
  end
end

function M.watch_translation_files()
  local cfg = config.get_config()
  if not cfg.watch_files then return false end

  -- vim.uv is the stable API in nvim 0.10+; vim.loop is the deprecated alias
  local uv = vim.uv or vim.loop
  if not uv then
    vim.notify("i18n: libuv not available, file watching disabled", vim.log.levels.WARN)
    return false
  end

  for _, lang in ipairs(cfg.languages) do
    local filepath = cfg.translation_path .. lang .. ".json"
    if vim.fn.filereadable(filepath) == 0 then goto continue end

    local ok, fs_event = pcall(uv.new_fs_event)
    if not ok then goto continue end

    local ok2, err = pcall(function()
      fs_event:start(filepath, {}, vim.schedule_wrap(function(err_msg)
        if err_msg then return end
        if reload_timers[lang] then reload_timers[lang]:stop() end
        reload_timers[lang] = vim.defer_fn(function()
          M.on_file_change(filepath, lang)
          reload_timers[lang] = nil
        end, cfg.debounce_ms)
      end))
    end)

    if ok2 then
      config.file_watchers[lang] = fs_event
    else
      vim.notify(string.format("i18n: Failed to watch '%s': %s", lang, err), vim.log.levels.WARN)
    end

    ::continue::
  end

  return true
end

function M.stop_watching()
  for _, fs_event in pairs(config.file_watchers) do
    if fs_event then pcall(function() fs_event:stop() end) end
  end
  config.file_watchers = {}
  for _, timer in pairs(reload_timers) do
    if timer then timer:stop() end
  end
  reload_timers = {}
end

return M
