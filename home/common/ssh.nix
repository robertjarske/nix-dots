_: {
  # keychain starts ssh-agent in the user's terminal, giving it a controlling
  # terminal so FIDO2 verify-required keys can prompt for PIN + touch.
  programs.keychain = {
    enable = true;
    enableZshIntegration = true;
    keys = ["id_ed25519_sk" "id_ed25519_sk_2"];
    extraFlags = ["--quiet" "--ignore-missing"];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      forwardAgent = false; # Never forward the agent — prevents lateral movement if a remote is compromised
      setEnv = {TERM = "xterm-256color";};
    };

    # Multiplex SSH connections so FIDO2 PIN + touch is only required once,
    # then reused for subsequent git operations within the persist window.
    matchBlocks."github.com" = {
      controlMaster = "auto";
      controlPath = "~/.ssh/cm-%r@%h:%p";
      controlPersist = "10m";
    };
  };
}
