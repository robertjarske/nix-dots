{
  pkgs,
  lib,
  config,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  home.packages = [pkgs.rofi];

  xdg = {
    # Hide rofi's own entries from the app launcher
    dataFile = {
      "applications/rofi.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Rofi
        NoDisplay=true
      '';

      "applications/rofi-theme-selector.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Rofi Theme Selector
        NoDisplay=true
      '';
    };

    configFile."rofi/master-config.rasi".text = ''
      /*****----- Configuration -----*****/
      configuration {
          font:                 "Fira Code SemiBold 8";
          modi:                 "drun,run,filebrowser,window";
          show-icons:           true;
          display-drun:         " Apps";
          display-run:          " Run";
          display-filebrowser:  " Files";
          display-window:       " Windows";
          drun-display-format:  "{name} [<span weight='light' size='small'><i>({generic})</i></span>]";
          hover-select:         true;
          me-select-entry:      "MouseSecondary";
          me-accept-entry:      "MousePrimary";
          window-format:        "{w} · {c} · {t}";
          dpi:                  1;
      }

      /*****----- Load matugen colors -----*****/
      @import "~/.config/rofi/matugen/colors-rofi.rasi"

      /*****----- Global Properties -----*****/
      * {
          border-colour:               var(selected);
          handle-colour:               var(selected);
          background-colour:           var(background);
          foreground-colour:           var(foreground);
          alternate-background:        var(background-alt);
          normal-background:           var(background);
          normal-foreground:           var(foreground);
          urgent-background:           var(urgent);
          urgent-foreground:           var(background);
          active-background:           var(active);
          active-foreground:           var(background);
          selected-normal-background:  var(selected);
          selected-normal-foreground:  var(background);
          selected-urgent-background:  var(active);
          selected-urgent-foreground:  var(background);
          selected-active-background:  var(urgent);
          selected-active-foreground:  var(background);
          alternate-normal-background: var(background);
          alternate-normal-foreground: var(foreground);
          alternate-urgent-background: var(urgent);
          alternate-urgent-foreground: var(background);
          alternate-active-background: var(active);
          alternate-active-foreground: var(background);

          /* Layout sizing — override per-resolution in config.rasi */
          screen-margin:   150px 250px;
          box-spacing:     15px;
          list-padding:    8px;
          element-padding: 12px;
          element-radius:  8px;
          element-spacing: 12px;
      }

      /*****----- Main Window -----*****/
      window {
          enabled:          true;
          fullscreen:       true;
          transparency:     "real";
          location:         center;
          anchor:           center;
          border:           0px solid;
          border-radius:    0px;
          border-color:     var(border-colour);
          cursor:           "default";
          background-color: rgba(0,0,0,0.5);
      }

      /*****----- Main Box -----*****/
      mainbox {
          enabled:          true;
          spacing:          var(box-spacing);
          margin:           var(screen-margin);
          padding:          var(box-spacing);
          border:           2px solid;
          border-radius:    12px;
          border-color:     var(border-colour);
          background-color: var(background-colour);
          children:         [ "inputbar", "message", "listview" ];
      }

      /*****----- Inputbar -----*****/
      inputbar {
          enabled:          true;
          spacing:          0px;
          padding:          0px;
          border:           0px solid;
          border-radius:    var(element-radius);
          border-color:     var(border-colour);
          background-color: transparent;
          text-color:       var(foreground-colour);
          children:         [ "textbox-prompt-colon", "entry", "mode-switcher" ];
      }

      textbox-prompt-colon {
          enabled:          true;
          expand:           false;
          padding:          var(element-padding);
          str:              "";
          border:           0px solid;
          border-radius:    var(element-radius);
          border-color:     var(border-colour);
          background-color: var(alternate-background);
          text-color:       var(foreground-colour);
      }
      entry {
          enabled:           true;
          expand:            true;
          padding:           var(element-padding);
          background-color:  inherit;
          text-color:        inherit;
          cursor:            text;
          placeholder:       "Search...";
          placeholder-color: inherit;
      }
      num-filtered-rows {
          enabled:          true;
          expand:           false;
          background-color: inherit;
          text-color:       inherit;
      }
      textbox-num-sep {
          enabled:          true;
          expand:           false;
          str:              "/";
          background-color: inherit;
          text-color:       inherit;
      }
      num-rows {
          enabled:          true;
          expand:           false;
          background-color: inherit;
          text-color:       inherit;
      }

      /*****----- Mode Switcher -----*****/
      mode-switcher {
          enabled:          true;
          spacing:          var(box-spacing);
          border:           0px solid;
          border-color:     var(border-colour);
          background-color: transparent;
          text-color:       var(foreground-colour);
      }
      button {
          padding:          var(element-padding);
          width:            130px;
          border:           0px solid;
          border-radius:    var(element-radius);
          border-color:     var(border-colour);
          background-color: var(alternate-background);
          text-color:       inherit;
          cursor:           pointer;
      }
      button selected {
          background-color: var(selected-normal-background);
          text-color:       var(selected-normal-foreground);
      }

      /*****----- Listview -----*****/
      listview {
          enabled:          true;
          columns:          1;
          lines:            10;
          cycle:            true;
          dynamic:          true;
          scrollbar:        true;
          layout:           vertical;
          reverse:          false;
          fixed-height:     true;
          fixed-columns:    true;
          spacing:          var(box-spacing);
          border:           0px solid;
          border-color:     var(border-colour);
          background-color: transparent;
          text-color:       var(foreground-colour);
          cursor:           "default";
      }
      scrollbar {
          handle-width:     8px;
          handle-color:     var(handle-colour);
          border-radius:    var(element-radius);
          background-color: var(alternate-background);
      }

      /*****----- Elements -----*****/
      element {
          enabled:          true;
          spacing:          var(element-spacing);
          padding:          var(list-padding);
          border:           0px solid;
          border-radius:    var(element-radius);
          border-color:     var(border-colour);
          background-color: transparent;
          text-color:       var(foreground-colour);
          cursor:           pointer;
      }
      element normal.normal {
          background-color: var(normal-background);
          text-color:       var(normal-foreground);
      }
      element normal.urgent {
          background-color: var(urgent-background);
          text-color:       var(urgent-foreground);
      }
      element normal.active {
          background-color: var(active-background);
          text-color:       var(active-foreground);
      }
      element selected.normal {
          background-color: var(selected-normal-background);
          text-color:       var(selected-normal-foreground);
      }
      element selected.urgent {
          background-color: var(selected-urgent-background);
          text-color:       var(selected-urgent-foreground);
      }
      element selected.active {
          background-color: var(selected-active-background);
          text-color:       var(selected-active-foreground);
      }
      element alternate.normal {
          background-color: var(alternate-normal-background);
          text-color:       var(alternate-normal-foreground);
      }
      element alternate.urgent {
          background-color: var(alternate-urgent-background);
          text-color:       var(alternate-urgent-foreground);
      }
      element alternate.active {
          background-color: var(alternate-active-background);
          text-color:       var(alternate-active-foreground);
      }
      element-icon {
          background-color: transparent;
          text-color:       inherit;
          size:             32px;
          cursor:           inherit;
      }
      element-text {
          background-color: transparent;
          text-color:       inherit;
          highlight:        inherit;
          cursor:           inherit;
          vertical-align:   0.5;
          horizontal-align: 0.0;
      }

      /*****----- Message -----*****/
      message {
          enabled:          true;
          padding:          0px;
          border:           0px solid;
          border-color:     var(border-colour);
          background-color: transparent;
          text-color:       var(foreground-colour);
      }
      textbox {
          padding:          var(element-padding);
          border:           0px solid;
          border-radius:    var(element-radius);
          border-color:     var(border-colour);
          background-color: var(alternate-background);
          text-color:       var(foreground-colour);
          vertical-align:   0.5;
          horizontal-align: 0.0;
          highlight:        none;
          blink:            true;
          markup:           true;
      }
      error-message {
          padding:          var(element-padding);
          border:           0px solid;
          border-color:     var(border-colour);
          background-color: var(background-colour);
          text-color:       var(foreground-colour);
      }
    '';

    configFile."rofi/config.rasi".text = ''
      @import "~/.config/rofi/master-config.rasi"

      /* Tighter margins on 1440p — keeps the panel as a focused strip */
      mainbox {
          margin: 200px 750px;
      }
    '';
  };

  # matugen/colors-rofi.rasi is generated at runtime from the current wallpaper.
  # Recreate the fallback if missing OR if it has the old format (migration).
  home.activation.rofiMatugenFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
        colors_file="${homeDir}/.config/rofi/matugen/colors-rofi.rasi"
        if [ ! -f "$colors_file" ] || ! grep -q 'selected:' "$colors_file"; then
          mkdir -p "$(dirname "$colors_file")"
          cat > "$colors_file" << 'ROFI_COLORS'
    /* Catppuccin Mocha fallback (overwritten by matugen on wallpaper change) */
    * {
        background:     #1e1e2e;
        background-alt: #313244;
        foreground:     #cdd6f4;
        selected:       #cba6f7;
        active:         #45475a;
        urgent:         #f38ba8;
    }
    ROFI_COLORS
        fi
  '';
}
