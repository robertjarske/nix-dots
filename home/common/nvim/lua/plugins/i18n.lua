return {
  {
    -- Local plugin: files live at lua/i18n-helper/ in the nvim config
    dir = vim.fn.stdpath("config") .. "/lua/i18n-helper",
    name = "i18n-helper",

    -- No telescope dependency — uses snacks picker (LazyVim default) with telescope as fallback
    dependencies = { "nvim-lua/plenary.nvim" },

    event = "VeryLazy",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    cmd = { "I18nSwitch", "I18nReload", "I18nSearch", "I18nToggle", "I18nStats" },

    keys = {
      { "<leader>il", "<cmd>I18nSwitch<cr>",  desc = "i18n: Switch Language" },
      { "<leader>ir", "<cmd>I18nReload<cr>",  desc = "i18n: Reload" },
      { "<leader>if", "<cmd>I18nSearch<cr>",  desc = "i18n: Find" },
      { "<leader>it", "<cmd>I18nToggle<cr>",  desc = "i18n: Toggle" },
    },

    config = function()
      require("i18n-helper").setup({
        -- translation_path auto-detected from git root (src/i18n/translation/)
        languages = { "en", "se", "cn" },
        current_language = "en",
        fallback_language = "en",
        cache_size = 500,
        debounce_ms = 200,
        watch_files = true,
        max_file_size = 10000,
      })
    end,
  },
}
