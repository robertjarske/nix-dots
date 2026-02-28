{ pkgs, unstable, ... }:
{
  environment.systemPackages = [
    unstable.neovim
    unstable.vscode
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}