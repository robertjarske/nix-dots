{ hyprpanel, pkgs, ... }:
{
  # HyprPanel is sourced from its own flake (not yet in nixpkgs as of 2026-02).
  # It is launched via exec-once in hyprland.nix.
  home.packages = [ hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # No home-manager module yet — configure via the GUI on first launch.
  # Settings are saved to ~/.config/ags/config.json automatically.
}
