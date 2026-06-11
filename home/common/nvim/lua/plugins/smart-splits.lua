-- Seamless navigation between Neovim splits and Kitty panes.
-- Requires in kitty.conf (via kitty.nix):
--   allow_remote_control yes
--   listen_on unix:/tmp/mykitty
return {
  {
    "mrjones2014/smart-splits.nvim",
    build = "./kitty/install-kittens.bash",
    lazy = false,
    keys = {
      -- Move between splits/panes (replaces LazyVim's plain <C-w>hjkl)
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to lower split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to upper split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      -- Resize splits
      { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
    },
    opts = {
      multiplexer_integration = "kitty",
      kitty_password = nil,
    },
  },
}
