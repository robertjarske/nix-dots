return {
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        hover = {
          silent = true,
        },
      },
      views = {
        hover = {
          border = { style = "rounded" },
          size = { max_width = 80 },
          win_options = { winblend = 0 },
        },
      },
    },
  },
}
