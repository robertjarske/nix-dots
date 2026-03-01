{ pkgs, lib, config, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  home.packages = [ pkgs.rofi ];

  xdg.configFile."rofi/master-config.rasi".text = ''
    /* Master Config 1440p */

    /* ---- Configuration ---- */
    configuration {
    	font:						"Fira Code SemiBold 13";
    	modi:                       "drun,run,filebrowser";
        show-icons:                 true;
        display-drun:               "Apps";
        display-run:                "Run";
        display-filebrowser:        "Files";
        display-window:             "Windows";
    	drun-display-format:        "{name}";
    	hover-select:               true;
    	me-select-entry:            "MouseSecondary";
        me-accept-entry:            "MousePrimary";
    	window-format:              "{w} · {c} · {t}";
    	dpi:						1;
    }

    /* ---- Load matugen colors (generated at runtime from wallpaper) ---- */
    @theme "~/.config/rofi/matugen/colors-rofi.rasi"

    /* ---- Global Properties ---- */
    * {
        background-alt:              @selected-active-background;
        selected:                    @selected-urgent-background;
        active:                      @selected-normal-background;
        urgent:                      @selected;

        text-selected:               @background;
        text-color:                  @foreground;
        border-color:                @selected;
    }

    /* ---- Window ---- */
    window {
        enabled:                    true;
        fullscreen:                 false;
        transparency:               "real";
        cursor:                     "default";
        spacing:                    0px;
        border:                     4px 0px 4px 0px;
        border-radius:              30px;
        location:                   center;
        anchor:                     center;

        width:                      50%;
        background-color:           @background;
    }

    /* ----- Main Box ----- */
    mainbox {
    	padding:					 15px;
        enabled:                     true;
        orientation:                 vertical;
        children:                    [ "inputbar", "listbox" ];
        background-color:            @background;
    }

    /* ---- Inputbar ---- */
    inputbar {
        enabled:                     true;
        padding:                     10px 10px 100px 10px;
        margin:                      10px;
        background-color:            transparent;
        border-radius:               25px;
        orientation:                 horizontal;
        children:                    ["entry", "dummy", "mode-switcher" ];
        background-image:            url("~/.config/rofi/.current_wallpaper", width);
    }

    /* ---- Entry input ---- */
    entry {
        enabled:                     true;
        expand:                      false;
        width:                       20%;
        padding:                     10px;
        border-radius:               12px;
        background-color:            @selected;
        text-color:                  @text-selected;
        cursor:                      text;
        placeholder:                 "🖥️ Search ";
        placeholder-color:           inherit;
    }

    /* ---- Listbox ---- */
    listbox {
        spacing:                     10px;
        padding:                     10px;
        background-color:            transparent;
        orientation:                 vertical;
        children:                    [ "message", "listview" ];
    }

    /* ---- Listview ---- */
    listview {
        enabled:                     true;
        columns:                     2;
        lines:                       6;
        cycle:                       true;
        dynamic:                     true;
        scrollbar:                   true;
        layout:                      vertical;
        reverse:                     false;
        fixed-height:                false;
        fixed-columns:               true;
        spacing:                     10px;
        background-color:            transparent;
        border:                      0px;
    }

    /* ---- Dummy ---- */
    dummy {
        expand:                      true;
        background-color:            transparent;
    }

    /* ---- Mode Switcher ---- */
    mode-switcher{
        enabled:                     true;
        spacing:                     10px;
        background-color:            transparent;
    }
    button {
        width:                       5%;
        padding:                     12px;
        border-radius:               12px;
        background-color:            @text-selected;
        text-color:                  @text-color;
        cursor:                      pointer;
    }
    button selected {
        background-color:            @selected;
        text-color:                  @text-selected;
    }

    /* ---- Scrollbar ---- */
    scrollbar {
        width:        4px;
        border:       0;
        handle-color: @border-color;
        handle-width: 8px;
        padding:      0;
    }

    /* ---- Elements ---- */
    element {
        enabled:                     true;
        spacing:                     10px;
        padding:                     10px;
        border-radius:               12px;
        background-color:            transparent;
        cursor:                      pointer;
    }

    element normal.normal {
        background-color:            inherit;
        text-color:                  inherit;
    }
    element normal.urgent {
        background-color:            @urgent;
        text-color:                  @foreground;
    }
    element normal.active {
        background-color:            @active;
        text-color:                  @foreground;
    }
    element selected.normal {
        border:                      1px 6px 1px 6px;
        border-radius:               16px;
        border-color:                @selected;
        background-color:            transparent;
        text-color:                  @selected;
    }
    element selected.urgent {
        background-color:            @urgent;
        text-color:                  @text-selected;
    }
    element selected.active {
        background-color:            @urgent;
        text-color:                  @text-selected;
    }
    element alternate.normal {
        background-color:            transparent;
        text-color:                  inherit;
    }
    element alternate.urgent {
        background-color:            transparent;
        text-color:                  inherit;
    }
    element alternate.active {
        background-color:            transparent;
        text-color:                  inherit;
    }
    element-icon {
        background-color:            transparent;
        text-color:                  inherit;
        cursor:                      inherit;
    }
    element-text {
        font:						"Fira Code SemiBold 16";
        background-color:            transparent;
        text-color:                  inherit;
        cursor:                      inherit;
        vertical-align:              0.5;
        horizontal-align:            0.0;
    }

    /* ---- Message ---- */
    message {
        background-color:            transparent;
        border:                      0px;
    }
    textbox {
        padding:                     12px;
        border-radius:               10px;
        background-color:            @background-alt;
        text-color:                  @background;
        vertical-align:              0.5;
        horizontal-align:            0.0;
    }
    error-message {
        padding:                     12px;
        border-radius:               20px;
        background-color:            @background-alt;
        text-color:                  @background;
    }
  '';

  # Per-resolution overrides for 1440p (imported over master-config)
  xdg.configFile."rofi/config.rasi".text = ''
    @import "~/.config/rofi/master-config.rasi"

    window {
        width: 60%;
    }
    entry {
        width: 18%;
    }
    button {
        width: 110px;
    }
    listview {
      columns: 6;
      lines: 4;
      fixed-height: true;
    }
    element {
      orientation: vertical;
      padding: 12px 0px 0px 0px;
      spacing: 6px;
      border-radius: 12px;
    }
    element-icon {
      size: 5%;
    }
    element-text {
      font: "Fira Code SemiBold 12";
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }
  '';

  # matugen/colors-rofi.rasi is generated at runtime from the current wallpaper.
  # Create a static fallback only if the file doesn't exist yet, so matugen can
  # freely overwrite it. The fallback uses neutral dark tones matching the base palette.
  home.activation.rofiMatugenFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    colors_file="${homeDir}/.config/rofi/matugen/colors-rofi.rasi"
    if [ ! -f "$colors_file" ]; then
      mkdir -p "$(dirname "$colors_file")"
      cat > "$colors_file" << 'ROFI_COLORS'
/* Catppuccin Mocha fallback (overwritten by matugen on wallpaper change) */
* {
    background:                 #1e1e2e;
    foreground:                 #cdd6f4;
    selected-active-background: #313244;
    selected-urgent-background: #cba6f7;
    selected-normal-background: #45475a;
}
ROFI_COLORS
    fi
  '';
}
