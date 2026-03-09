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

    # Separate config for HyprPanel — run with --contrast 1 so button
    # colors are pushed to maximum brightness against the dark bar background.
    "matugen/config-hyprpanel.toml".text = ''
      [config]
      reload_apps = false
      set_wallpaper = false
      prefix = '@'

      [templates]
      hyprpanel.input_path  = '~/.config/matugen/templates/hyprpanel-theme.json'
      hyprpanel.output_path = '~/.config/ags/hyprpanel-matugen-theme.json'
    '';

    # Templates — matugen processes these with Material You colors extracted
    # from the current wallpaper and writes the output files above.

    "matugen/templates/colors-hyprland.conf".text = ''
      <* for name, value in colors *>
      ''${{name}} = rgba({{value.default.hex_stripped}}ff)
      <* endfor *>
    '';

    # Rofi color palette
    # master-config.rasi references these with var(background), var(selected), etc.
    "matugen/templates/colors-rofi.rasi".text = ''
      * {
          background:     {{colors.surface.default.hex}};
          background-alt: {{colors.primary_container.default.hex}};
          foreground:     {{colors.on_surface.default.hex}};
          selected:       {{colors.primary.default.hex}};
          active:         {{colors.surface_container_high.default.hex}};
          urgent:         {{colors.error.default.hex}};
      }
    '';

    # HyprPanel theme — all ~370 color keys mapped from Material You roles.
    # Loaded at runtime via: hyprpanel useTheme ~/.config/ags/hyprpanel-matugen-theme.json
    # Color role strategy:
    #   surface_dim              → deepest backgrounds (bar, menu bg)
    #   surface_container_low    → card backgrounds
    #   surface_container        → button backgrounds
    #   surface_container_high   → borders, feint text
    #   surface_container_highest→ hover states, slider track
    #   on_surface               → main text
    #   on_surface_variant       → passive/secondary text
    #   outline / outline_variant→ muted/status text
    #   primary                  → main accent (labels, icons, sliders)
    #   secondary                → network, updates, battery, microphone
    #   tertiary                 → bluetooth, clock, submap, cava
    #   primary_container        → clock button, window title, calendar
    #   secondary_container      → media album, weather hourly
    #   error                    → power/shutdown, CPU, close buttons
    #   on_primary/secondary/tertiary/error → text on respective accent bg
    "matugen/templates/hyprpanel-theme.json".text = ''
      {
        "theme.bar.menus.menu.notifications.scrollbar.color": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.notifications.pager.label": "{{colors.on_surface_variant.default.hex}}",
        "theme.bar.menus.menu.notifications.pager.button": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.notifications.pager.background": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.notifications.switch.puck": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.notifications.switch.disabled": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.notifications.switch.enabled": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.notifications.clear": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.notifications.switch_divider": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.notifications.border": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.notifications.card": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.notifications.background": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.notifications.no_notifications_label": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.notifications.label": "{{colors.primary.default.hex}}",

        "theme.bar.menus.menu.power.buttons.sleep.icon": "{{colors.on_tertiary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.sleep.text": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.sleep.icon_background": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.sleep.background": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.power.buttons.logout.icon": "{{colors.on_secondary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.logout.text": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.logout.icon_background": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.logout.background": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.power.buttons.restart.icon": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.restart.text": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.restart.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.power.buttons.restart.background": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.power.buttons.shutdown.icon": "{{colors.on_error.default.hex}}",
        "theme.bar.menus.menu.power.buttons.shutdown.text": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.power.buttons.shutdown.icon_background": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.power.buttons.shutdown.background": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.power.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.power.background.color": "{{colors.surface_dim.default.hex}}",

        "theme.bar.menus.menu.dashboard.monitors.disk.label": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.disk.bar": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.disk.icon": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.gpu.label": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.gpu.bar": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.gpu.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.ram.label": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.ram.bar": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.ram.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.cpu.label": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.cpu.bar": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.cpu.icon": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.dashboard.monitors.bar_background": "{{colors.surface_container_highest.default.hex}}",

        "theme.bar.menus.menu.dashboard.directories.right.bottom.color": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.directories.right.middle.color": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.directories.right.top.color": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.directories.left.bottom.color": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.dashboard.directories.left.middle.color": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.directories.left.top.color": "{{colors.secondary_container.default.hex}}",

        "theme.bar.menus.menu.dashboard.controls.input.text": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.input.background": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.volume.text": "{{colors.on_error.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.volume.background": "{{colors.error_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.notifications.text": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.notifications.background": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.bluetooth.text": "{{colors.on_tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.bluetooth.background": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.wifi.text": "{{colors.on_secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.wifi.background": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.controls.disabled": "{{colors.surface_container_highest.default.hex}}",

        "theme.bar.menus.menu.dashboard.shortcuts.recording": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.shortcuts.text": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.shortcuts.background": "{{colors.primary.default.hex}}",

        "theme.bar.menus.menu.dashboard.powermenu.confirmation.button_text": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.deny": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.confirm": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.body": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.label": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.border": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.background": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.confirmation.card": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.sleep": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.logout": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.restart": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.dashboard.powermenu.shutdown": "{{colors.error.default.hex}}",

        "theme.bar.menus.menu.dashboard.profile.name": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.dashboard.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.dashboard.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.dashboard.card.color": "{{colors.surface_container_low.default.hex}}",

        "theme.bar.menus.menu.clock.weather.hourly.temperature": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.clock.weather.hourly.icon": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.clock.weather.hourly.time": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.clock.weather.thermometer.extremelycold": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.clock.weather.thermometer.cold": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.clock.weather.thermometer.moderate": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.clock.weather.thermometer.hot": "{{colors.error_container.default.hex}}",
        "theme.bar.menus.menu.clock.weather.thermometer.extremelyhot": "{{colors.error.default.hex}}",
        "theme.bar.menus.menu.clock.weather.stats": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.clock.weather.status": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.clock.weather.temperature": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.clock.weather.icon": "{{colors.secondary_container.default.hex}}",

        "theme.bar.menus.menu.clock.calendar.contextdays": "{{colors.outline_variant.default.hex}}",
        "theme.bar.menus.menu.clock.calendar.days": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.clock.calendar.currentday": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.clock.calendar.paginator": "{{colors.primary_container.default.hex}}",
        "theme.bar.menus.menu.clock.calendar.weekdays": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.clock.calendar.yearmonth": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.clock.time.timeperiod": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.clock.time.time": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.clock.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.clock.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.clock.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.clock.card.color": "{{colors.surface_container_low.default.hex}}",

        "theme.bar.menus.menu.battery.slider.puck": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.battery.slider.backgroundhover": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.battery.slider.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.battery.slider.primary": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.battery.icons.active": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.battery.icons.passive": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.battery.listitems.active": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.battery.listitems.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.battery.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.battery.label.color": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.battery.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.battery.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.battery.card.color": "{{colors.surface_container_low.default.hex}}",

        "theme.bar.menus.menu.systray.dropdownmenu.divider": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.systray.dropdownmenu.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.systray.dropdownmenu.background": "{{colors.surface_dim.default.hex}}",

        "theme.bar.menus.menu.bluetooth.iconbutton.active": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.bluetooth.iconbutton.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.bluetooth.icons.active": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.bluetooth.icons.passive": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.bluetooth.listitems.active": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.bluetooth.listitems.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.bluetooth.switch.puck": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.bluetooth.switch.disabled": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.bluetooth.switch.enabled": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.bluetooth.switch_divider": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.bluetooth.status": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.bluetooth.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.bluetooth.label.color": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.bluetooth.scroller.color": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.bluetooth.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.bluetooth.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.bluetooth.card.color": "{{colors.surface_container_low.default.hex}}",

        "theme.bar.menus.menu.network.iconbuttons.active": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.network.iconbuttons.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.network.icons.active": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.network.icons.passive": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.network.listitems.active": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.network.listitems.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.network.status.color": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.network.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.network.label.color": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.network.scroller.color": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.network.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.network.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.network.card.color": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.network.switch.enabled": "{{colors.secondary.default.hex}}",
        "theme.bar.menus.menu.network.switch.disabled": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.network.switch.puck": "{{colors.surface_container_highest.default.hex}}",

        "theme.bar.menus.menu.volume.input_slider.puck": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.volume.input_slider.backgroundhover": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.volume.input_slider.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.volume.input_slider.primary": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.volume.audio_slider.puck": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.volume.audio_slider.backgroundhover": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.volume.audio_slider.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.volume.audio_slider.primary": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.volume.icons.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.volume.icons.passive": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.volume.iconbutton.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.volume.iconbutton.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.volume.listitems.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.volume.listitems.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.volume.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.volume.label.color": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.volume.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.volume.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.volume.card.color": "{{colors.surface_container_low.default.hex}}",

        "theme.bar.menus.menu.media.slider.puck": "{{colors.outline.default.hex}}",
        "theme.bar.menus.menu.media.slider.backgroundhover": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.media.slider.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.media.slider.primary": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.media.buttons.text": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.menu.media.buttons.background": "{{colors.primary.default.hex}}",
        "theme.bar.menus.menu.media.buttons.enabled": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.media.buttons.inactive": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.menu.media.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.menu.media.card.color": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.menu.media.background.color": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.menu.media.album": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.menu.media.timestamp": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.menu.media.artist": "{{colors.tertiary.default.hex}}",
        "theme.bar.menus.menu.media.song": "{{colors.primary.default.hex}}",

        "theme.bar.menus.tooltip.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.tooltip.background": "{{colors.surface_dim.default.hex}}",
        "theme.bar.menus.dropdownmenu.divider": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.dropdownmenu.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.dropdownmenu.background": "{{colors.surface_dim.default.hex}}",

        "theme.bar.menus.slider.puck": "{{colors.outline.default.hex}}",
        "theme.bar.menus.slider.backgroundhover": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.slider.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.slider.primary": "{{colors.primary.default.hex}}",
        "theme.bar.menus.progressbar.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.progressbar.foreground": "{{colors.primary.default.hex}}",
        "theme.bar.menus.iconbuttons.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.iconbuttons.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.buttons.text": "{{colors.on_primary.default.hex}}",
        "theme.bar.menus.buttons.disabled": "{{colors.outline.default.hex}}",
        "theme.bar.menus.buttons.active": "{{colors.secondary_container.default.hex}}",
        "theme.bar.menus.buttons.default": "{{colors.primary.default.hex}}",
        "theme.bar.menus.check_radio_button.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.check_radio_button.background": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.switch.puck": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.menus.switch.disabled": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.switch.enabled": "{{colors.primary.default.hex}}",
        "theme.bar.menus.icons.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.icons.passive": "{{colors.outline_variant.default.hex}}",
        "theme.bar.menus.listitems.active": "{{colors.primary.default.hex}}",
        "theme.bar.menus.listitems.passive": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.popover.border": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.popover.background": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.popover.text": "{{colors.primary.default.hex}}",
        "theme.bar.menus.label": "{{colors.primary.default.hex}}",
        "theme.bar.menus.feinttext": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.dimtext": "{{colors.outline_variant.default.hex}}",
        "theme.bar.menus.text": "{{colors.on_surface.default.hex}}",
        "theme.bar.menus.border.color": "{{colors.surface_container_high.default.hex}}",
        "theme.bar.menus.cards": "{{colors.surface_container_low.default.hex}}",
        "theme.bar.menus.background": "{{colors.surface_dim.default.hex}}",

        "theme.bar.buttons.modules.power.icon_background": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.power.icon": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.power.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.power.border": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.weather.icon_background": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.weather.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.weather.text": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.weather.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.weather.border": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.updates.icon_background": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.updates.icon": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.updates.text": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.updates.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.updates.border": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.kbLayout.icon_background": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.kbLayout.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.kbLayout.text": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.kbLayout.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.kbLayout.border": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.netstat.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.netstat.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.netstat.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.netstat.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.netstat.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.storage.icon_background": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.storage.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.storage.text": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.storage.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.storage.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.cpu.icon_background": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.cpu.icon": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.cpu.text": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.cpu.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.cpu.border": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.ram.icon_background": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.ram.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.ram.text": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.ram.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.ram.border": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.submap.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.submap.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.submap.icon_background": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.submap.text": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.submap.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.hyprsunset.icon": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.hyprsunset.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.hyprsunset.icon_background": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.hyprsunset.text": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.hyprsunset.border": "{{colors.error.default.hex}}",
        "theme.bar.buttons.modules.hypridle.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.hypridle.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.hypridle.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.hypridle.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.hypridle.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.cava.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.cava.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.cava.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.cava.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.cava.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.modules.worldclock.text": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.worldclock.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.worldclock.icon_background": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.worldclock.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.worldclock.border": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.modules.microphone.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.microphone.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.modules.microphone.text": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.microphone.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.modules.microphone.icon_background": "{{colors.secondary.default.hex}}",

        "theme.bar.buttons.notifications.total": "{{colors.error.default.hex}}",
        "theme.bar.buttons.notifications.icon_background": "{{colors.error.default.hex}}",
        "theme.bar.buttons.notifications.icon": "{{colors.error.default.hex}}",
        "theme.bar.buttons.notifications.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.notifications.border": "{{colors.error.default.hex}}",
        "theme.bar.buttons.clock.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.clock.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.clock.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.clock.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.clock.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.battery.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.battery.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.battery.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.battery.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.battery.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.systray.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.systray.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.systray.customIcon": "{{colors.on_surface.default.hex}}",
        "theme.bar.buttons.bluetooth.icon_background": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.bluetooth.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.bluetooth.text": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.bluetooth.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.bluetooth.border": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.network.icon_background": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.network.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.network.text": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.network.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.network.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.volume.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.volume.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.volume.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.volume.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.volume.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.media.icon_background": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.media.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.media.text": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.media.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.media.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.windowtitle.icon_background": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.windowtitle.icon": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.windowtitle.text": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.windowtitle.border": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.windowtitle.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.workspaces.numbered_active_underline_color": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.workspaces.numbered_active_highlighted_text_color": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.workspaces.hover": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.workspaces.active": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.workspaces.occupied": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.workspaces.available": "{{colors.secondary.default.hex}}",
        "theme.bar.buttons.workspaces.border": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.workspaces.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.dashboard.icon": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.dashboard.border": "{{colors.tertiary.default.hex}}",
        "theme.bar.buttons.dashboard.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.icon": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.text": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.hover": "{{colors.surface_container_highest.default.hex}}",
        "theme.bar.buttons.icon_background": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.background": "{{colors.surface_container.default.hex}}",
        "theme.bar.buttons.borderColor": "{{colors.primary.default.hex}}",
        "theme.bar.buttons.style": "default",
        "theme.bar.background": "{{colors.surface_dim.default.hex}}",
        "theme.bar.border.color": "{{colors.primary.default.hex}}",

        "theme.osd.label": "{{colors.primary.default.hex}}",
        "theme.osd.icon": "{{colors.on_primary.default.hex}}",
        "theme.osd.bar_overflow_color": "{{colors.error.default.hex}}",
        "theme.osd.bar_empty_color": "{{colors.surface_container_high.default.hex}}",
        "theme.osd.bar_color": "{{colors.primary.default.hex}}",
        "theme.osd.icon_container": "{{colors.primary.default.hex}}",
        "theme.osd.bar_container": "{{colors.surface_dim.default.hex}}",

        "theme.notification.close_button.label": "{{colors.on_error.default.hex}}",
        "theme.notification.close_button.background": "{{colors.error.default.hex}}",
        "theme.notification.labelicon": "{{colors.primary.default.hex}}",
        "theme.notification.text": "{{colors.on_surface.default.hex}}",
        "theme.notification.time": "{{colors.outline.default.hex}}",
        "theme.notification.border": "{{colors.surface_container_high.default.hex}}",
        "theme.notification.label": "{{colors.primary.default.hex}}",
        "theme.notification.actions.text": "{{colors.on_primary.default.hex}}",
        "theme.notification.actions.background": "{{colors.primary.default.hex}}",
        "theme.notification.background": "{{colors.surface_container_low.default.hex}}"
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
