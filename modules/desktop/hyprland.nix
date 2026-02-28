{ pkgs, ... }:
{
  # Required for dconf/GSettings to work in user sessions — without this,
  # dark mode preference and GTK settings written by home-manager don't persist.
  programs.dconf.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG portal for screen sharing, file pickers etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";        # Electron apps use Wayland
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix cursor on some hardware
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  environment.systemPackages = with pkgs; [
    hyprpaper        # Wallpaper
    hyprlock         # Lock screen
    hypridle         # Idle management
    hyprshot         # Screenshots
    wl-clipboard     # Clipboard
    brightnessctl    # Brightness control
    playerctl        # Media key control
    wofi             # Launcher
  ];
}