-- Virtual text rendering using extmarks

local config = require("i18n-helper.config")
local patterns = require("i18n-helper.patterns")
local translation = require("i18n-helper.translation")
local M = {}

function M.setup_namespace()
  if not config.virtual_text_ns then
    config.virtual_text_ns = vim.api.nvim_create_namespace("i18n_helper")
  end
  return config.virtual_text_ns
end

local function get_cached_translation(key)
  local lang = config.get_current_language()
  local cache = config.cache
  local cache_key = lang .. ":" .. key

  if cache then
    local cached = cache:get(cache_key)
    if cached then return cached end
  end

  local trans = translation.get_translation(key, lang)

  -- Don't cache or render missing translations
  if trans:match("%[MISSING%]$") then return nil end

  if cache then cache:set(cache_key, trans) end
  return trans
end

local function truncate(text, max_len)
  max_len = max_len or 60
  if #text <= max_len then return text end
  return text:sub(1, max_len - 1) .. "…"
end

function M.clear_buffer(bufnr)
  local ns_id = M.setup_namespace()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.clear_line(bufnr, linenr)
  local ns_id = M.setup_namespace()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, linenr - 1, linenr)
end

--- Render inline virtual text for each translation key on a line
function M.render_line(bufnr, linenr)
  if not config.is_virtual_text_enabled() then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local ns_id = M.setup_namespace()
  local cfg = config.get_config()

  M.clear_line(bufnr, linenr)

  local lines = vim.api.nvim_buf_get_lines(bufnr, linenr - 1, linenr, false)
  if #lines == 0 then return end

  local matches = patterns.find_translation_keys_in_line(lines[1], linenr)
  if #matches == 0 then return end

  for _, match in ipairs(matches) do
    local trans = get_cached_translation(match.key)
    if trans then
      local hint = cfg.virtual_text_prefix .. truncate(trans)
      pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, linenr - 1, match.end_col, {
        virt_text = { { hint, cfg.virtual_text_highlight } },
        virt_text_pos = "inline",
        priority = 100,
      })
    end
  end
end

function M.render_buffer(bufnr)
  if not config.is_virtual_text_enabled() then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local cfg = config.get_config()
  if vim.api.nvim_buf_line_count(bufnr) > cfg.max_file_size then return end

  M.clear_buffer(bufnr)

  local matches = patterns.find_translation_keys_in_buffer(bufnr)
  if #matches == 0 then return end

  local grouped = patterns.group_by_line(matches)
  for linenr in pairs(grouped) do
    M.render_line(bufnr, linenr)
  end
end

function M.update_debounced(bufnr)
  local cfg = config.get_config()
  if config.debounce_timers[bufnr] then
    config.debounce_timers[bufnr]:stop()
  end
  config.debounce_timers[bufnr] = vim.defer_fn(function()
    M.render_buffer(bufnr)
    config.debounce_timers[bufnr] = nil
  end, cfg.debounce_ms)
end

function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("i18n_helper", { clear = true })

  local id1 = vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
    group = group,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function(args) M.render_buffer(args.buf) end,
  })

  local id2 = vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function(args) M.update_debounced(args.buf) end,
  })

  local id3 = vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(args)
      M.clear_buffer(args.buf)
      if config.debounce_timers[args.buf] then
        config.debounce_timers[args.buf]:stop()
        config.debounce_timers[args.buf] = nil
      end
    end,
  })

  table.insert(config.autocmd_ids, id1)
  table.insert(config.autocmd_ids, id2)
  table.insert(config.autocmd_ids, id3)
end

function M.refresh_all_buffers()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(bufnr) then
      -- Fixed: use vim.bo instead of deprecated nvim_buf_get_option
      local ft = vim.bo[bufnr].filetype
      if vim.tbl_contains({ "typescript", "typescriptreact", "javascript", "javascriptreact" }, ft) then
        M.render_buffer(bufnr)
      end
    end
  end
end

return M
