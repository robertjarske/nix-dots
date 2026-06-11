return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "css", "html", "javascript", "jsdoc", "json", "jsonc",
        "lua", "luadoc", "markdown", "markdown_inline", "nix", "php",
        "phpdoc", "regex", "toml", "tsx", "typescript", "vim", "vimdoc",
        "yaml",
      },
      -- LazyVim calls nvim-treesitter.configs.setup(opts) internally,
      -- so textobjects config goes here rather than in a separate config function.
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "outer function" },
            ["if"] = { query = "@function.inner", desc = "inner function" },
            ["ac"] = { query = "@class.outer",    desc = "outer class" },
            ["ic"] = { query = "@class.inner",    desc = "inner class" },
            ["aa"] = { query = "@parameter.outer", desc = "outer argument" },
            ["ia"] = { query = "@parameter.inner", desc = "inner argument" },
            ["ab"] = { query = "@block.outer",    desc = "outer block" },
            ["ib"] = { query = "@block.inner",    desc = "inner block" },
          },
        },
        swap = {
          enable = true,
          swap_next     = { ["<leader>csn"] = { query = "@parameter.inner", desc = "Swap argument →" } },
          swap_previous = { ["<leader>csp"] = { query = "@parameter.inner", desc = "Swap argument ←" } },
        },
      },
    },
  },
}
