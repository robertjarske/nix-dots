{
  neovimNightly,
  unstable,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    neovimNightly
    unstable.claude-code
    pkgs.gcc # required by nvim-treesitter to compile parsers
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
