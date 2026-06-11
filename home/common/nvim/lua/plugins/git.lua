return {
  -- Diffview - Modern diff and merge tool
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gd", group = "diff/diffview" },
      { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Open DiffView" },
      { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Close DiffView" },
      { "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
      { "<leader>gdH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch History" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    },
  },

  -- Fugitive - Classic git integration
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep" },
    keys = {
      { "<leader>gf", group = "fugitive" },
      { "<leader>gff", "<cmd>Git<cr>", desc = "Fugitive Status" },
      { "<leader>gfv", "<cmd>Gvdiffsplit<cr>", desc = "Vertical Diff" },
      { "<leader>gfl", "<cmd>Git log<cr>", desc = "Git Log" },
      { "<leader>gfp", "<cmd>Git push<cr>", desc = "Git Push" },
      { "<leader>gfP", "<cmd>Git pull<cr>", desc = "Git Pull" },
    },
  },

  -- Configure gitsigns (already installed)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(buffer)
        local gs = require("gitsigns")

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- Navigation: Swedish-friendly pattern ([ ] require AltGr on Swedish keyboards)
        pcall(vim.keymap.del, "n", "]h", { buffer = buffer })
        pcall(vim.keymap.del, "n", "[h", { buffer = buffer })
        map("n", "<leader>gh.", gs.next_hunk, "Next Hunk")
        map("n", "<leader>gh,", gs.prev_hunk, "Prev Hunk")

        -- Hunk actions
        map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
        map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")
        map("v", "<leader>ghs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage Hunk")
        map("v", "<leader>ghr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")

        -- Blame
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame Line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle Line Blame")
      end,
    },
  },
}
