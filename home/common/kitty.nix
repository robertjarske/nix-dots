{ lib, config, ... }:
{
  # Catppuccin Mocha fallback — written on first activation so kitty can start
  # before matugen has generated ~/.config/kitty/kitty-colors.conf.
  # Once wallpaper-change runs, matugen overwrites this file.
  home.activation.kittyColorsFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    colors_file="${config.home.homeDirectory}/.config/kitty/kitty-colors.conf"
    if [ ! -f "$colors_file" ]; then
      mkdir -p "$(dirname "$colors_file")"
      cat > "$colors_file" << 'EOF'
# Catppuccin Mocha (fallback until matugen runs)
cursor            #cdd6f4
cursor_text_color #1e1e2e

foreground           #cdd6f4
background           #1e1e2e
selection_foreground #cdd6f4
selection_background #313244
url_color            #89b4fa

active_tab_background   #cba6f7
active_tab_foreground   #1e1e2e
inactive_tab_background #313244
inactive_tab_foreground #cdd6f4
tab_bar_background      #11111b
tab_bar_margin_color    #11111b

scrollbar_handle_color #cba6f7
scrollbar_track_color  #313244

color0  #45475a
color8  #585b70
color1  #f38ba8
color9  #f38ba8
color2  #a6e3a1
color10 #a6e3a1
color3  #f9e2af
color11 #f9e2af
color4  #89b4fa
color12 #89b4fa
color5  #f5c2e7
color13 #cba6f7
color6  #94e2d5
color14 #94e2d5
color7  #bac2de
color15 #a6adc8
EOF
    fi
  '';

  programs.kitty = {
    enable = true;

    font = {
      name = "FiraCode Nerd Font";
      size = 10;
    };

    settings = {
      # --- Font ---
      bold_font        = "auto";
      italic_font      = "auto";
      bold_italic_font = "auto";
      # Retina variant: +zero makes 0 distinguishable, +ss06 is FiraCode's arrow ligatures
      font_features = "FiraCodeNerdFont-Retina +zero +ss06";

      # --- Scrollback ---
      scrollback_lines = 10000;

      # --- Appearance ---
      background_opacity      = "0.9";
      window_padding_width    = 8;
      hide_window_decorations = true;
      draw_minimal_borders    = true;
      window_border_width     = 0;

      # --- Tab bar ---
      tab_bar_edge              = "top";
      tab_bar_style             = "powerline";
      tab_powerline_style       = "slanted";
      tab_title_template        = "{fmt.fg.c2c2c2}{title}";
      active_tab_title_template = "{fmt.fg._fff}{title}";
      active_tab_font_style     = "bold-italic";

      # --- Bell ---
      visual_bell_duration = "0.0";
      enable_audio_bell    = false;

      # --- URLs ---
      open_url_modifiers = "ctrl+shift";
      open_url_with      = "default";

      # --- Terminal ---
      term                  = "xterm-kitty";
      linux_display_server  = "auto";
      update_check_interval = 0;

    };

    # Colors are managed by matugen (see home/common/matugen.nix).
    # matugen writes ~/.config/kitty/kitty-colors.conf on each wallpaper change;
    # kitty reloads it live via SIGUSR1 sent by the wallpaper-change script.
    extraConfig = "include ~/.config/kitty/kitty-colors.conf";

    keybindings = {
      # Fix Ctrl+Left/Right word navigation.
      # Default kitty behaviour can trigger backward-kill-word (deletes the word)
      # instead of backward-word (moves cursor). Explicitly sending the correct
      # ANSI codes (\e[1;5D / \e[1;5C) matches the bindkey mappings in zsh.nix.
      "ctrl+left"  = "send_text application \\x1b[1;5D";
      "ctrl+right" = "send_text application \\x1b[1;5C";
    };
  };
}
