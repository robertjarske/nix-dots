_: {
  programs.git = {
    enable = true;
    settings = {
      user.name = "Robert Jarske Eriksson";
      user.email = "jarske.eriksson@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = "!gh auth git-credential";
    };
  };
}
