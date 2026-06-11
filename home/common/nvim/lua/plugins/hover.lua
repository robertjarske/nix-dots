return {
  {
    "lewis6991/hover.nvim",
    event = "VeryLazy",
    keys = {
      { "K",  function() require("hover").open() end,  desc = "Hover" },
      { "gK", function() require("hover").enter() end, desc = "Hover (enter)" },
    },
    config = function()
      require("hover").config({
        providers = {
          "hover.providers.lsp",
          "hover.providers.diagnostic",
        },
        mouse_providers = {
          "hover.providers.lsp",
          "hover.providers.diagnostic",
        },
        mouse_delay = 800,
        preview_opts = { border = "rounded" },
        preview_window = false,
        title = true,
      })
    end,
  },
}
