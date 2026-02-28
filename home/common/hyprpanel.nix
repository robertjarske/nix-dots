{ hyprpanel, pkgs, ... }:
{
  # HyprPanel is sourced from its own flake (not yet in nixpkgs as of 2026-02).
  # It is launched via exec-once in hyprland.nix.
  home.packages = [ hyprpanel.packages.${pkgs.system}.default ];

  # programs.hyprpanel is not available in home-manager release-25.11.
  # Configure HyprPanel via the GUI on first launch — settings are saved
  # to ~/.config/ags/config.json automatically.
  #
  # When home-manager gains the module (upstream PR is open), migrate
  # settings here using programs.hyprpanel.settings.*
  # Reference: https://hyprpanel.com/configuration/settings.html
  #
  # Useful options to set once the module is available:
  #   programs.hyprpanel.settings = {
  #     layout.bar.layouts."0" = {
  #       left   = [ "dashboard" "workspaces" "windowtitle" ];
  #       middle = [ "media" ];
  #       right  = [ "volume" "network" "battery" "systray" "clock" "notifications" ];
  #     };
  #     bar.launcher.autoDetectIcon = true;
  #     bar.workspaces.show_icons    = true;
  #     menus.clock.time.military    = true;
  #     menus.dashboard.stats.enable_gpu = true;
  #     theme.font.name = "FiraCode Nerd Font";
  #     theme.font.size = "13px";
  #   };
}
