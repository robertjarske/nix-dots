return {
  -- Disable which-key: it shows statically-registered descriptions, not live keymaps.
  -- mini.clue replaces it by reading Vim's actual keymap registry.
  { "folke/which-key.nvim", enabled = false },

  {
    "nvim-mini/mini.clue",
    event = "VeryLazy",
    config = function()
      local clue = require("mini.clue")
      clue.setup({
        triggers = {
          { mode = "n", keys = "<Leader>" },
          { mode = "x", keys = "<Leader>" },
          { mode = "n", keys = "g" },
          { mode = "n", keys = "z" },
          { mode = "n", keys = "'" },
          { mode = "n", keys = "`" },
          { mode = "n", keys = '"' },
          { mode = "n", keys = "<C-w>" },
          { mode = "i", keys = "<C-x>" },
        },
        clues = {
          -- Group names: prefix descriptions that have no keymap of their own.
          -- Individual key descriptions come from vim.keymap.set desc= fields (always accurate).
          { mode = "n", keys = "<Leader>a",     desc = "+AI" },
          { mode = "n", keys = "<Leader>b",     desc = "+buffer" },
          { mode = "n", keys = "<Leader>c",     desc = "+code" },
          { mode = "n", keys = "<Leader>cs",    desc = "+swap" },
          { mode = "n", keys = "<Leader>d",     desc = "+debug" },
          { mode = "n", keys = "<Leader>f",     desc = "+find/file" },
          { mode = "n", keys = "<Leader>g",     desc = "+git" },
          { mode = "n", keys = "<Leader>gd",    desc = "+diff" },
          { mode = "n", keys = "<Leader>gf",    desc = "+fugitive" },
          { mode = "n", keys = "<Leader>gh",    desc = "+hunks" },
          { mode = "n", keys = "<Leader>q",     desc = "+quit/session" },
          { mode = "n", keys = "<Leader>r",     desc = "+references" },
          { mode = "n", keys = "<Leader>R",     desc = "+rest/http" },
          { mode = "n", keys = "<Leader>s",     desc = "+search" },
          { mode = "n", keys = "<Leader>t",     desc = "+terminal/test" },
          { mode = "n", keys = "<Leader>T",     desc = "+todo" },
          { mode = "n", keys = "<Leader>u",     desc = "+ui" },
          { mode = "n", keys = "<Leader>w",     desc = "+windows" },
          { mode = "n", keys = "<Leader>i",     desc = "+i18n" },
          { mode = "n", keys = "<Leader>x",     desc = "+diagnostics" },
          { mode = "n", keys = "<Leader>xe",    desc = "+errors" },
          { mode = "n", keys = "<Leader>xw",    desc = "+warnings" },
          { mode = "n", keys = "<Leader><Tab>", desc = "+tabs" },
          { mode = "x", keys = "<Leader>g",     desc = "+git" },
          { mode = "x", keys = "<Leader>gh",    desc = "+hunks" },
          -- Built-in Vim documentation (marks, registers, folds, windows, completion)
          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.marks(),
          clue.gen_clues.registers(),
          clue.gen_clues.windows(),
          clue.gen_clues.z(),
        },
        window = {
          delay = 300,
          config = {
            border = "rounded",
            width = "auto",
          },
          scroll_down = "<C-d>",
          scroll_up = "<C-u>",
        },
      })
    end,
  },
}
