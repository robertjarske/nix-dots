-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use Intelephense for PHP LSP (default is phpactor)
vim.g.lazyvim_php_lsp = "intelephense"

-- CursorHold (auto-hover) fires after this many ms of cursor inactivity.
-- hover.nvim uses mouse_delay = 800 for mouse hover independently of this.
vim.opt.updatetime = 800

vim.diagnostic.config({
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})
