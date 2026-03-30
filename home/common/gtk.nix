{config, pkgs, ...}: {
  gtk = {
    enable = true;

    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = ["mauve"];
        variant = "mocha";
      };
    };

    cursorTheme = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
      theme = config.gtk.theme;
    };
  };

  # Cursor for Wayland and X11 sessions
  home.pointerCursor = {
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # dconf — GTK4/libadwaita apps and portal dialogs read preferences from here
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "catppuccin-mocha-mauve-standard";
    icon-theme = "Papirus-Dark";
    cursor-theme = "catppuccin-mocha-dark-cursors";
    cursor-size = 24;
  };
}
