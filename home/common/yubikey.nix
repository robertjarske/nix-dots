{pkgs, ...}: {
  # Automatically learn GPG card stubs at login and on YubiKey insertion.
  # Without this, GPG prompts "insert card with serial ..." even when the key is plugged in.
  #
  # GPG signing key: 8FAA99B1062B8E5A6A2D1B4E448A22DB4777E844
  # On reinstall: import backup, keytocard to both YubiKeys, then delete local master key.
  # Backup is stored in 1Password.
  systemd.user.services.gpg-card-learn = {
    Unit = {
      Description = "Learn GPG card stubs from YubiKey";
      Wants = "gpg-agent.service";
      After = "gpg-agent.service";
    };
    Service = {
      Type = "oneshot";
      # Kill scdaemon first so it restarts clean — avoids "No such device" when
      # scdaemon starts before the card is fully enumerated and gets stuck in bad state.
      ExecStart = let
        script = pkgs.writeShellScript "gpg-card-learn" ''
          ${pkgs.gnupg}/bin/gpg-connect-agent "SCD KILLSCD" /bye
          sleep 1
          ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
        '';
      in "${script}";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["default.target"];
  };
}
