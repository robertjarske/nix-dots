{config, ...}: {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "vivaldi-stable.desktop";
        "x-scheme-handler/https" = "vivaldi-stable.desktop";
        "x-scheme-handler/ftp" = "vivaldi-stable.desktop";
        "x-scheme-handler/chrome" = "vivaldi-stable.desktop";
        "text/html" = "vivaldi-stable.desktop";
        "application/xhtml+xml" = "vivaldi-stable.desktop";

        "inode/directory" = "org.gnome.Nautilus.desktop";
        "x-scheme-handler/file" = "org.gnome.Nautilus.desktop";

        # Image viewer
        "image/jpeg" = "swayimg.desktop";
        "image/png" = "swayimg.desktop";
        "image/gif" = "swayimg.desktop";
        "image/webp" = "swayimg.desktop";
        "image/svg+xml" = "swayimg.desktop";
        "image/tiff" = "swayimg.desktop";
        "image/bmp" = "swayimg.desktop";
        "image/avif" = "swayimg.desktop";
        "image/heic" = "swayimg.desktop";
      };
    };
    desktopEntries.swayimg = {
      name = "Swayimg";
      genericName = "Image viewer";
      exec = "${config.home.homeDirectory}/.local/bin/swayimg-open %u";
      terminal = false;
      categories = ["Graphics" "Viewer"];
      mimeType = [
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/heic"
        "image/jpeg"
        "image/png"
        "image/svg+xml"
        "image/tiff"
        "image/webp"
      ];
    };
    configFile."swayimg/config".text = ''
      [keys.viewer]
      Left = prev_file
      Right = next_file
      Up = step_up 10
      Down = step_down 10
      Alt+Left = step_left 10
      Alt+Right = step_right 10
      Delete = exec rm -f '%'; skip_file
    '';
    userDirs = {
      enable = true;
      createDirectories = true;
      # Explicit English names — avoids locale-dependent directory names on first login.
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
    };
  };

  # Wrapper: opens the file AND its parent directory so arrow-key navigation works
  home.file.".local/bin/swayimg-open" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec swayimg "$1" "$(dirname "$1")"
    '';
  };
}
