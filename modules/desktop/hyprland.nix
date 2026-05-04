{
  pkgs,
  unstable,
  ...
}: {
  # Required for dconf/GSettings to work in user sessions — without this,
  # dark mode preference and GTK settings written by home-manager don't persist.
  programs.dconf.enable = true;

  programs.hyprland = {
    enable = true;
    package = unstable.hyprland;
    portalPackage = unstable.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    # Hyprland 0.50+ ships a hyprland-uwsm.desktop session that SDDM picks up.
    # withUWSM installs the required systemd user unit templates; without it
    # uwsm start fails immediately and the session never launches.
    withUWSM = true;
  };

  # XDG portal for screen sharing, file pickers etc.
  xdg.portal = {
    enable = true;
    extraPortals = [
      unstable.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # needed for GTK file pickers and app choosers
    ];
    # Keyed to XDG_CURRENT_DESKTOP=Hyprland (matched case-insensitively).
    # Explicit per-interface routing avoids the wildcard fallback picking the
    # wrong backend — screen capture must go to hyprland, file pickers to gtk.
    config.hyprland = {
      default = ["hyprland" "gtk"];
      "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
      "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
      "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron apps use Wayland
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    # Set at the session level (not just in Hyprland's env block) so that
    # D-Bus/systemd-activated services like xdg-desktop-portal inherit it.
    GTK_THEME = "catppuccin-mocha-mauve-standard:dark";
  };

  environment.systemPackages = with pkgs; [
    hyprpaper # Wallpaper daemon
    hyprlock # Lock screen
    hypridle # Idle management
    hyprpolkitagent # Polkit authentication agent
    grimblast # Screenshots (area/window/output selection, copies to clipboard + saves file)
    wl-clipboard # Wayland clipboard (wl-copy/wl-paste)
    cliphist # Clipboard history
    brightnessctl # Brightness control
    playerctl # Media key control
    networkmanagerapplet # NM system tray (VPN toggle, connection editing)
    wofi # Launcher (fallback)
  ];
}
