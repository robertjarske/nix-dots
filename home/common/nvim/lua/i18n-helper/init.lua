-- i18n Translation Helper Plugin

local config = require("i18n-helper.config")
local translation = require("i18n-helper.translation")
local cache_module = require("i18n-helper.cache")
local virtual_text = require("i18n-helper.virtual_text")
local file_watcher = require("i18n-helper.file_watcher")

local M = {}

function M.setup(opts)
  if not config.setup(opts) then return end

  config.cache = cache_module.new(config.get_config().cache_size)
  virtual_text.setup_namespace()

  vim.defer_fn(function()
    -- If path wasn't found at setup time, try now (cwd may have changed)
    if config.get_config().translation_path == "" then
      if not config.redetect_path() then return end
    end

    translation.load_all_translations()
    virtual_text.setup_autocmds()

    if config.get_config().watch_files then
      file_watcher.watch_translation_files()
    end

    M.create_commands()
  end, 100)
end

function M.create_commands()
  vim.api.nvim_create_user_command("I18nSwitch", function(cmd_opts)
    if cmd_opts.args and cmd_opts.args ~= "" then
      M.switch_language(cmd_opts.args)
    else
      M.switch_language_picker()
    end
  end, {
    nargs = "?",
    complete = function() return config.get_config().languages end,
    desc = "Switch i18n display language",
  })

  vim.api.nvim_create_user_command("I18nReload", function()
    M.reload_translations()
  end, { desc = "Reload all translation files" })

  vim.api.nvim_create_user_command("I18nSearch", function()
    M.search_translations()
  end, { desc = "Search translations" })

  vim.api.nvim_create_user_command("I18nToggle", function()
    M.toggle_virtual_text()
  end, { desc = "Toggle virtual text display" })

  vim.api.nvim_create_user_command("I18nStats", function()
    M.show_stats()
  end, { desc = "Show cache statistics" })
end

function M.switch_language_picker()
  local cfg = config.get_config()
  local current = config.get_current_language()
  local lang_names = { en = "English", se = "Swedish", cn = "Chinese" }
  local choices = {}
  for _, lang in ipairs(cfg.languages) do
    local display = string.format("%s (%s)", lang_names[lang] or lang, lang)
    if lang == current then display = display .. " ✓" end
    table.insert(choices, { lang = lang, display = display })
  end
  vim.ui.select(choices, {
    prompt = "Choose language:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then M.switch_language(choice.lang) end
  end)
end

function M.switch_language(lang)
  if not config.set_current_language(lang) then
    vim.notify(string.format("i18n: Invalid language '%s'", lang), vim.log.levels.ERROR)
    return
  end
  vim.notify(string.format("i18n: Switched to '%s'", lang), vim.log.levels.INFO)
  virtual_text.refresh_all_buffers()
end

function M.reload_translations()
  if config.get_config().translation_path == "" then
    config.redetect_path()
  end
  if config.cache then config.cache:clear() end
  translation.load_all_translations()
  virtual_text.refresh_all_buffers()
  vim.notify("i18n: Translations reloaded", vim.log.levels.INFO)
end

function M.toggle_virtual_text()
  config.toggle_virtual_text()
  if config.is_virtual_text_enabled() then
    vim.notify("i18n: Virtual text enabled", vim.log.levels.INFO)
    virtual_text.refresh_all_buffers()
  else
    vim.notify("i18n: Virtual text disabled", vim.log.levels.INFO)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(bufnr) then
        virtual_text.clear_buffer(bufnr)
      end
    end
  end
end

function M.search_translations()
  -- Try snacks picker first (LazyVim default), fall back to telescope
  local has_snacks, snacks = pcall(require, "snacks")
  if has_snacks and snacks.picker then
    local keys = translation.get_all_keys()
    if #keys == 0 then
      vim.notify("i18n: No translations loaded", vim.log.levels.WARN)
      return
    end
    local items = {}
    for _, key in ipairs(keys) do
      local trans = translation.get_all_translations(key)
      table.insert(items, {
        text = key .. " " .. (trans.en or ""),
        key = key,
        label = string.format("%-25s %s", key, trans.en or "[MISSING]"),
      })
    end
    snacks.picker.pick({
      title = "i18n Translations",
      items = items,
      format = function(item) return { { item.label, "Normal" } } end,
      confirm = function(picker, item)
        picker:close()
        if item then vim.api.nvim_put({ item.key }, "", true, true) end
      end,
    })
    return
  end

  -- Telescope fallback
  local has_telescope = pcall(require, "telescope")
  if has_telescope then
    require("i18n-helper.telescope_picker").search_translations()
    return
  end

  vim.notify("i18n: No picker available (snacks or telescope required)", vim.log.levels.WARN)
end

function M.get_translation(key, lang)
  return translation.get_translation(key, lang)
end

function M.refresh_current_buffer()
  virtual_text.render_buffer(vim.api.nvim_get_current_buf())
end

function M.show_stats()
  if not config.cache then
    vim.notify("i18n: Cache not initialized", vim.log.levels.WARN)
    return
  end
  local s = config.cache:stats()
  vim.notify(string.format(
    "i18n Cache:\nHits: %d | Misses: %d | Rate: %s | Size: %d/%d",
    s.hits, s.misses, s.hit_rate, s.size, s.max_size
  ), vim.log.levels.INFO)
end

function M.cleanup()
  file_watcher.stop_watching()
  config.cleanup()
end

return M
