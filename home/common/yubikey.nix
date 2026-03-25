{pkgs, ...}: {
  # Automatically learn GPG card stubs at login and on YubiKey insertion.
  # Without this, GPG prompts "insert card with serial ..." even when the key is plugged in.
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
