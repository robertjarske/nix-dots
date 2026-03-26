{pkgs, ...}: {
  # ksshaskpass shows a proper PIN dialog for FIDO2 UV (verify-required) keys.
  # Wrapped to suppress KWallet-not-found errors — we intentionally run without
  # kwalletd so the PIN is never saved and is always re-asked after ControlPersist
  # expires (enforcing the idle-timeout re-auth behaviour).
  # SSH_ASKPASS_REQUIRE=prefer ensures a single GUI prompt rather than the
  # sk-helper and main ssh process both prompting simultaneously.
  home.packages = [pkgs.kdePackages.ksshaskpass];
  home.file.".local/bin/ssh-askpass" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec ${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass "$@" 2>/dev/null
    '';
  };
  home.sessionVariables = {
    SSH_ASKPASS = "$HOME/.local/bin/ssh-askpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "no";
      forwardAgent = false; # Never forward — prevents lateral movement if a remote host is compromised
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
