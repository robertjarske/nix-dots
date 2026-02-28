{ ... }:
{
  programs.ssh = {
    enable = true;

    # Add keys to the running agent on first use so subsequent connections
    # don't prompt for the passphrase again in the same session.
    addKeysToAgent = "yes";

    # Keep TERM set to something sane on remote hosts. Kitty's terminfo is
    # rarely present on servers; xterm-256color degrades gracefully everywhere.
    extraConfig = "SetEnv TERM=xterm-256color";
  };
}
