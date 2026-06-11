return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http" },
    keys = {
      { "<leader>R", group = "rest" },
      { "<leader>Rs", function() require("kulala").run() end, desc = "Send Request" },
      { "<leader>Ra", function() require("kulala").run_all() end, desc = "Send All" },
      { "<leader>Ri", function() require("kulala").inspect() end, desc = "Inspect Request" },
      { "<leader>Rc", function() require("kulala").copy() end, desc = "Copy as cURL" },
      { "<leader>Rp", function() require("kulala").jump_prev() end, desc = "Prev Request" },
      { "<leader>Rn", function() require("kulala").jump_next() end, desc = "Next Request" },
    },
    opts = {
      default_view = "body",
      display_mode = "split",
      split_direction = "vertical",
    },
  },
}
