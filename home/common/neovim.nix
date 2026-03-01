{ config, lib, ... }:
{
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # lazy-lock.json is included in the nvim/ source, so home-manager creates it
  # as a read-only symlink. Replace it with a mutable regular file so lazy.nvim
  # can write to it on :Lazy update.
  # The autocmd in autocmds.lua auto-copies it back to the repo on every write.
  home.activation.nvimMutableLazyLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    lockfile="${config.xdg.configHome}/nvim/lazy-lock.json"
    if [ -L "$lockfile" ]; then
      target="$(readlink "$lockfile")"
      rm "$lockfile"
      cp "$target" "$lockfile"
      chmod 644 "$lockfile"
    fi
  '';
}