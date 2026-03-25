_: {
  programs.git = {
    enable = true;
    settings = {
      alias = {
        wta = "worktree add";
        wtl = "worktree list";
        wtr = "worktree remove";
        wtrf = "worktree remove --force";
        wtp = "worktree prune";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = "!gh auth git-credential";
      commit.gpgSign = true;
      tag.gpgSign = true;
    };
  };
}
