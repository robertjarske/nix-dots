-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Swedish Keyboard Optimization
-- This file remaps keybindings that use hard-to-reach keys on Swedish keyboard layout
-- Problematic keys: [ ] / | ` (require AltGr or Shift combinations)

local map = vim.keymap.set
local del = vim.keymap.del

-- Register which-key groups for Swedish keyboard keymaps
vim.schedule(function()
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>r", group = "references", icon = "󰌹" },
      { "<leader>t", group = "terminal/test", icon = "󰆍" },
      { "<leader>T", group = "todo comments", icon = "󰄲" },
    })
  end
end)

-- ============================================================================
-- TERMINAL
-- ============================================================================
-- Replace <C-/> with <F12> (forward slash requires Shift+7 on Swedish keyboard)
pcall(del, { "n", "t" }, "<C-/>")
pcall(del, { "n", "t" }, "<C-_>")
map({ "n", "t" }, "<F12>", "<cmd>lua Snacks.terminal.toggle()<cr>", { desc = "Terminal (Root Dir)" })

-- ============================================================================
-- BUFFER NAVIGATION
-- ============================================================================
-- Use Tab and Shift-Tab for buffer navigation
pcall(del, "n", "[b")
pcall(del, "n", "]b")
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })

-- Replace <leader>` with <leader>ba (backtick is hard to reach)
pcall(del, "n", "<leader>`")
map("n", "<leader>ba", "<cmd>e #<cr>", { desc = "Alternate Buffer" })

-- Replace [B and ]B for moving buffers
pcall(del, "n", "[B")
pcall(del, "n", "]B")
map("n", "<leader>b<", "<cmd>BufferLineMovePrev<cr>", { desc = "Move Buffer Left" })
map("n", "<leader>b>", "<cmd>BufferLineMoveNext<cr>", { desc = "Move Buffer Right" })

-- ============================================================================
-- DIAGNOSTIC NAVIGATION
-- ============================================================================
-- Replace [d and ]d with <leader>d, and <leader>d.
pcall(del, "n", "[d")
pcall(del, "n", "]d")
map("n", "<leader>d,", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
map("n", "<leader>d.", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })

-- ============================================================================
-- ERROR NAVIGATION
-- ============================================================================
-- Replace [e and ]e with <leader>e, and <leader>e.
pcall(del, "n", "[e")
pcall(del, "n", "]e")
map("n", "<leader>e,", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous Error" })
map("n", "<leader>e.", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error" })

-- ============================================================================
-- WARNING NAVIGATION
-- ============================================================================
-- Replace [w and ]w with <leader>w, and <leader>w.
pcall(del, "n", "[w")
pcall(del, "n", "]w")
map("n", "<leader>w,", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Previous Warning" })
map("n", "<leader>w.", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Next Warning" })

-- ============================================================================
-- QUICKFIX NAVIGATION
-- ============================================================================
-- Replace [q and ]q with <leader>q, and <leader>q.
pcall(del, "n", "[q")
pcall(del, "n", "]q")
map("n", "<leader>q,", "<cmd>cprev<cr>", { desc = "Previous Quickfix" })
map("n", "<leader>q.", "<cmd>cnext<cr>", { desc = "Next Quickfix" })

-- ============================================================================
-- TODO COMMENT NAVIGATION
-- ============================================================================
-- Replace [t and ]t with <leader>T, and <leader>T.
pcall(del, "n", "[t")
pcall(del, "n", "]t")
map("n", "<leader>T,", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous Todo Comment" })
map("n", "<leader>T.", function()
  require("todo-comments").jump_next()
end, { desc = "Next Todo Comment" })

-- ============================================================================
-- REFERENCE NAVIGATION
-- ============================================================================
-- Replace [[ and ]] with <leader>r, and <leader>r.
pcall(del, "n", "[[")
pcall(del, "n", "]]")
map("n", "<leader>r,", function()
  require("illuminate").goto_prev_reference(false)
end, { desc = "Previous Reference" })
map("n", "<leader>r.", function()
  require("illuminate").goto_next_reference(false)
end, { desc = "Next Reference" })

-- ============================================================================
-- WINDOW SPLITS
-- ============================================================================
-- Replace <leader>| and <leader>- with <leader>wv and <leader>wh (pipe requires AltGr)
pcall(del, "n", "<leader>|")
pcall(del, "n", "<leader>-")
map("n", "<leader>wv", "<C-W>v", { desc = "Split Window Vertically" })
map("n", "<leader>wh", "<C-W>s", { desc = "Split Window Horizontally" })

-- ============================================================================
-- TAB NAVIGATION
-- ============================================================================
-- Replace <leader><tab>[ and <leader><tab>] with <leader><tab>, and <leader><tab>.
pcall(del, "n", "<leader><tab>[")
pcall(del, "n", "<leader><tab>]")
map("n", "<leader><tab>,", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader><tab>.", "<cmd>tabnext<cr>", { desc = "Next Tab" })

-- ============================================================================
-- YANK HISTORY (yanky.nvim)
-- ============================================================================
-- Replace [y and ]y with <M-p> and <M-n>
pcall(del, "n", "[y")
pcall(del, "n", "]y")
map("n", "<M-p>", function()
  require("yanky").cycle(-1)
end, { desc = "Previous Yank" })
map("n", "<M-n>", function()
  require("yanky").cycle(1)
end, { desc = "Next Yank" })

-- ============================================================================
-- ADDITIONAL SWEDISH KEYBOARD FRIENDLY MAPPINGS
-- ============================================================================
-- Add alternative terminal mappings
map("n", "<leader>tt", "<cmd>lua Snacks.terminal.toggle()<cr>", { desc = "Terminal (Root)" })
map(
  "n",
  "<leader>tT",
  "<cmd>lua Snacks.terminal.toggle(nil, { cwd = vim.fn.getcwd() })<cr>",
  { desc = "Terminal (cwd)" }
)
map("n", "<leader>tf", function()
  Snacks.terminal.toggle(nil, { win = { position = "float" } })
end, { desc = "Terminal (Floating)" })

-- ============================================================================
-- NOTES
-- ============================================================================
-- Swedish keyboard layout issues:
-- - / requires Shift+7 (problematic with Ctrl)
-- - [ requires AltGr+8
-- - ] requires AltGr+9
-- - | requires AltGr+< or similar
-- - ` (backtick) is in different location
--
-- This configuration replaces all these problematic keybindings with
-- easily accessible alternatives using comma (,) and period (.) for
-- prev/next patterns, which aligns with the directional concept
-- (comma points left, period continues right).
