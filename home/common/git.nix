_: {
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = "!gh auth git-credential";
    };
  };
}
