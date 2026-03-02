{unstable, ...}: {
  environment.systemPackages = [
    unstable.neovim
    unstable.vscode
    unstable.claude-code
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
