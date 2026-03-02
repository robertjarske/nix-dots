{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      forwardAgent = false; # Never forward the agent — prevents lateral movement if a remote is compromised
      setEnv = {TERM = "xterm-256color";};
    };
  };
}
