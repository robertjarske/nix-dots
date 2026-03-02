{pkgs, ...}: {
  home.packages = [pkgs.matugen];

  # config.toml — defines template → output mappings.
  # matugen is triggered manually or by the wallpaper-change script.
  # Run: matugen image /path/to/wallpaper
  xdg.configFile = {
    "matugen/config.toml".text = ''
      [config]
      reload_apps = false
      set_wallpaper = false
      prefix = '@'

      [templates]
      hypr.input_path  = '~/.config/matugen/templates/colors-hyprland.conf'
      hypr.output_path = '~/.config/hypr/matugen/matugen-hyprland.conf'

      rofi.input_path  = '~/.config/matugen/templates/colors-rofi.rasi'
      rofi.output_path = '~/.config/rofi/matugen/colors-rofi.rasi'

      kitty.input_path  = '~/.config/matugen/templates/colors-kitty.conf'
      kitty.output_path = '~/.config/kitty/kitty-colors.conf'
    '';

    # Templates — matugen processes these with Material You colors extracted
    # from the current wallpaper and writes the output files above.

    "matugen/templates/colors-hyprland.conf".text = ''
      <* for name, value in colors *>
      ''${{name}} = rgba({{value.default.hex_stripped}}ff)
      <* endfor *>
    '';

    # Rofi variables must match the names referenced in master-config.rasi.
    # Only these 5 are needed — master-config.rasi derives all other aliases from them.
    "matugen/templates/colors-rofi.rasi".text = ''
      * {
          background:                 {{colors.surface.default.hex}};
          foreground:                 {{colors.on_surface.default.hex}};
          selected-active-background: {{colors.primary_container.default.hex}};
          selected-urgent-background: {{colors.primary.default.hex}};
          selected-normal-background: {{colors.surface_container_high.default.hex}};
      }
    '';

    "matugen/templates/colors-kitty.conf".text = ''
      cursor            {{colors.on_surface.default.hex}}
      cursor_text_color {{colors.surface.default.hex}}

      foreground           {{colors.on_surface.default.hex}}
      background           {{colors.surface.default.hex}}
      selection_foreground {{colors.on_secondary.default.hex}}
      selection_background {{colors.secondary_fixed_dim.default.hex}}
      url_color            {{colors.primary.default.hex}}

      active_tab_background   {{colors.primary.default.hex}}
      active_tab_foreground   {{colors.on_primary.default.hex}}
      inactive_tab_background {{colors.surface_container.default.hex}}
      inactive_tab_foreground {{colors.on_surface_variant.default.hex}}
      tab_bar_background      {{colors.surface.default.hex}}
      tab_bar_margin_color    {{colors.surface.default.hex}}

      scrollbar_handle_color {{colors.primary.default.hex}}
      scrollbar_track_color  {{colors.surface_container.default.hex}}

      # black
      color8   #262626
      color0   #4c4c4c

      # red
      color1   #ac8a8c
      color9   #c49ea0

      # green
      color2   #8aac8b
      color10  #9ec49f

      # yellow
      color3   #aca98a
      color11  #c4c19e

      # blue
      color4  {{colors.primary.default.hex}}
      color12 #a39ec4

      # magenta
      color5   #ac8aac
      color13  #c49ec4

      # cyan
      color6   #8aacab
      color14  #9ec3c4

      # white
      color15  #e7e7e7
      color7   #f0f0f0
    '';
  };
}
