{...}: {
  imports = [
    ./common/zsh.nix
    ./common/kitty.nix
    ./common/starship.nix
    ./common/git.nix
    ./common/neovim.nix
    ./common/gtk.nix
    ./common/hyprland.nix
    ./common/rofi.nix
    ./common/matugen.nix
    ./common/hyprpanel.nix
    ./common/work-certs.nix
    ./common/fastfetch.nix
    ./common/ssh.nix
    ./common/vscode.nix
    ./common/mpv.nix
    ./common/direnv.nix
  ];

  # HiDPI laptop screen — 3840x2400 at 1.6 scale (effective 2400x1500).
  # The catch-all ",preferred,auto,1" from the common module handles any
  # external monitors plugged in without needing explicit config.
  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,3840x2400@60,0x0,1.6"
  ];

  home.stateVersion = "25.11";
}
