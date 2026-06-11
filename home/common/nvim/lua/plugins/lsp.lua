return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- nixd is installed via Nix (modules/dev/editors.nix).
      -- Prefer nixd over nil_ls — it understands flake expressions and NixOS options.
      opts.servers.nil_ls = nil
      opts.servers.nixd = {
        settings = {
          nixd = {
            formatting = {
              command = { "alejandra" },
            },
          },
        },
      }

      return opts
    end,
  },
}
