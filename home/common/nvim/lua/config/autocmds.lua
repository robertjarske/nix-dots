-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-sync lazy-lock.json back to the dotfiles repo after :Lazy update.
-- lazy.nvim writes the lockfile to ~/.config/nvim/lazy-lock.json; this copies
-- it to the repo so it stays in version control without manual intervention.
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "lazy-lock.json",
  callback = function()
    local src = vim.fn.stdpath("config") .. "/lazy-lock.json"
    local dots = vim.fn.expand("~/code/nix-dots/home/common/nvim/lazy-lock.json")
    if vim.fn.filereadable(src) == 1 and vim.fn.isdirectory(vim.fn.fnamemodify(dots, ":h")) == 1 then
      vim.fn.system({ "cp", src, dots })
    end
  end,
})

-- Set 4 space indentation for PHP files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
