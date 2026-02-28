return {
  -- Configure Snacks Explorer to show hidden and gitignored files
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,  -- Show hidden/dotfiles
            ignored = true, -- Show gitignored files
          },
        },
      },
    },
  },
}
