{pkgs, ...}: {
  # Qt platform theming — applies Catppuccin Mocha via Kvantum to Qt apps,
  # including xdg-desktop-portal-hyprland's screen-cast picker (Qt-based).
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # home-manager's qt module auto-installs the Qt5/Qt6 Kvantum style plugins
  # when style.name = "kvantum" — only the theme package needs to be listed.
  home.packages = [pkgs.catppuccin-kvantum];

  # Tell Kvantum which variant to use.
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Catppuccin-Mocha-Mauve
  '';
}
