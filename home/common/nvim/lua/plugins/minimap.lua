return {
  -- Satellite.nvim - VSCode-like scrollbar with git and diagnostic signs
  {
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    opts = {
      current_only = false,
      winblend = 0,
      zindex = 40,
      excluded_filetypes = {
        "help",
        "dashboard",
        "lazy",
        "mason",
        "notify",
        "toggleterm",
        "TelescopePrompt",
        "neo-tree",
        "NvimTree",
        "Trouble",
        "qf",
        "noice",
      },
      width = 2,
      handlers = {
        cursor = {
          enable = true,
          symbols = { '⎺', '⎻', '⎼', '⎽' }
        },
        diagnostic = {
          enable = true,
          signs = {'-', '=', '≡'},
          min_severity = vim.diagnostic.severity.HINT,
        },
        gitsigns = {
          enable = true,
          signs = {
            add = "│",
            change = "│",
            delete = "-",
          }
        },
        marks = {
          enable = true,
          show_builtins = false,
        },
        quickfix = {
          enable = true,
          signs = { '-', '=', '≡' },
        }
      },
    },
  },
}
