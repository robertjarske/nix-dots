{
  pkgs,
  lib,
  config,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  home.packages = [pkgs.rofi];

  xdg.configFile."rofi/master-config.rasi".text = ''
    /* Master Config — style-14 adapted for matugen */

    configuration {
        font:                 "Fira Code SemiBold 13";
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

    /* ---- Load matugen colors (generated at runtime from wallpaper) ---- */
    @theme "~/.config/rofi/matugen/colors-rofi.rasi"

    /* ---- Map matugen's 5 vars to style-14's full color semantics ---- */
    * {
        /* matugen source vars:
             background                → dark surface
             foreground                → light text
             selected-active-background  → elevated surface (bg-alt)
             selected-urgent-background  → accent / primary
             selected-normal-background  → secondary container   */

        border-colour:               @selected-urgent-background;
        handle-colour:               @selected-urgent-background;
        background-colour:           @background;
        foreground-colour:           @foreground;
        alternate-background:        @selected-active-background;

        normal-background:           @background;
        normal-foreground:           @foreground;
        urgent-background:           @selected-urgent-background;
        urgent-foreground:           @background;
        active-background:           @selected-normal-background;
        active-foreground:           @background;

        selected-normal-background:  @selected-urgent-background;
        selected-normal-foreground:  @background;
        selected-urgent-background:  @selected-normal-background;
        selected-urgent-foreground:  @background;
        selected-active-background:  @selected-urgent-background;
        selected-active-foreground:  @background;

        alternate-normal-background: @background;
        alternate-normal-foreground: @foreground;
        alternate-urgent-background: @selected-urgent-background;
        alternate-urgent-foreground: @background;
        alternate-active-background: @selected-normal-background;
        alternate-active-foreground: @background;

        /* Layout sizing — override per-resolution in config.rasi */
        screen-margin:   150px 300px;
        box-spacing:     15px;
        list-padding:    8px;
        element-padding: 12px;
        element-radius:  8px;
        element-spacing: 12px;
    }

    /* ---- Window (fullscreen overlay) ---- */
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
        background-color: var(background-colour);
    }

    /* ---- Main Box ---- */
    mainbox {
        enabled:          true;
        spacing:          var(box-spacing);
        margin:           var(screen-margin);
        padding:          0px;
        border:           0px solid;
        border-color:     var(border-colour);
        background-color: transparent;
        children:         [ "inputbar", "message", "listview" ];
    }

    /* ---- Inputbar ---- */
    inputbar {
        enabled:          true;
        spacing:          0px;
        padding:          0px;
        border:           0px solid;
        border-radius:    var(element-radius);
        border-color:     var(border-colour);
        background-color: transparent;
        text-color:       var(foreground-colour);
        children:         [ "textbox-prompt-colon", "entry", "num-filtered-rows", "textbox-num-sep", "num-rows", "mode-switcher" ];
    }

    textbox-prompt-colon {
        enabled:          true;
        expand:           false;
        padding:          var(element-padding);
        str:              " ";
        font:             "FiraCode Nerd Font 13";
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
        background-color:  @alternate-background;
        text-color:        @foreground-colour;
        cursor:            text;
        placeholder:       "Search...";
        placeholder-color: inherit;
    }

    num-filtered-rows {
        enabled:          true;
        expand:           false;
        padding:          var(element-padding);
        background-color: var(alternate-background);
        text-color:       var(foreground-colour);
    }
    textbox-num-sep {
        enabled:          true;
        expand:           false;
        str:              "/";
        padding:          0px 12px 0px 0px;
        background-color: var(alternate-background);
        text-color:       var(foreground-colour);
    }
    num-rows {
        enabled:          true;
        expand:           false;
        padding:          0px 12px 0px 0px;
        background-color: var(alternate-background);
        text-color:       var(foreground-colour);
    }

    /* ---- Mode Switcher ---- */
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
        width:            100px;
        border:           0px solid;
        border-radius:    var(element-radius);
        border-color:     var(border-colour);
        background-color: var(alternate-background);
        text-color:       var(foreground-colour);
        cursor:           pointer;
    }
    button selected {
        background-color: var(selected-normal-background);
        text-color:       var(selected-normal-foreground);
    }

    /* ---- Listview ---- */
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

    /* ---- Elements ---- */
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

    element normal.normal          { background-color: var(normal-background);           text-color: var(normal-foreground);           }
    element normal.urgent          { background-color: var(urgent-background);           text-color: var(urgent-foreground);           }
    element normal.active          { background-color: var(active-background);           text-color: var(active-foreground);           }
    element selected.normal        { background-color: var(selected-normal-background);  text-color: var(selected-normal-foreground);  }
    element selected.urgent        { background-color: var(selected-urgent-background);  text-color: var(selected-urgent-foreground);  }
    element selected.active        { background-color: var(selected-active-background);  text-color: var(selected-active-foreground);  }
    element alternate.normal       { background-color: var(alternate-normal-background); text-color: var(alternate-normal-foreground); }
    element alternate.urgent       { background-color: var(alternate-urgent-background); text-color: var(alternate-urgent-foreground); }
    element alternate.active       { background-color: var(alternate-active-background); text-color: var(alternate-active-foreground); }

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

    /* ---- Message ---- */
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

  # Per-resolution overrides for 1440p external monitors
  xdg.configFile."rofi/config.rasi".text = ''
    @import "~/.config/rofi/master-config.rasi"

    /* Tighter margins on 1440p — keeps the panel as a focused strip */
    mainbox {
        margin: 200px 750px;
    }
  '';

  # matugen/colors-rofi.rasi is generated at runtime from the current wallpaper.
  # Create a static fallback only if the file doesn't exist yet, so matugen can
  # freely overwrite it. The fallback uses neutral dark tones matching the base palette.
  home.activation.rofiMatugenFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
