{...}: {
  imports = [
    ./common/zsh.nix
    ./common/kitty.nix
    ./common/starship.nix
    ./common/git.nix
    ./common/neovim.nix
    ./common/gtk.nix
    ./common/qt.nix
    ./common/hyprland.nix
    ./common/rofi.nix
    ./common/matugen.nix
    ./common/hyprpanel.nix
    ./common/fastfetch.nix
    ./common/wlr-which-key.nix
    ./common/ssh.nix
    ./common/vscode.nix
    ./common/mpv.nix
    ./common/direnv.nix
    ./common/xdg.nix
  ];

  # HiDPI laptop screen — 3840x2400 at 1.6 scale (effective 2400x1500).
  # The catch-all ",preferred,auto,1" from the common module handles any
  # external monitors plugged in without needing explicit config.
  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,3840x2400@60,0x0,1.6"
  ];

  # Identity + signing key loaded from a locally-managed file, not tracked in this repo.
  # On first setup:
  #   printf '[user]\n  name = ...\n  email = ...\n  signingKey = YOUR_GPG_KEY_ID\n' \
  #     > ~/.config/git/local-identity
  programs.git.includes = [
    {path = "~/.config/git/local-identity";}
  ];

  home.stateVersion = "25.11";
}
