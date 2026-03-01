{ config, pkgs, lib, ... }:
let
  # Changes the wallpaper via hyprpaper IPC and regenerates Material You colors.
  # Keybind: CTRL+ALT+W  — also runs on startup via exec-once.
  wallpaper-change = pkgs.writeShellApplication {
    name = "wallpaper-change";
    runtimeInputs = [ pkgs.matugen ];
    text = ''
      wallpaper=$(find "$HOME/Pictures/wallpapers" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n1)
      hyprctl hyprpaper preload "$wallpaper"
      hyprctl hyprpaper wallpaper ",$wallpaper"
      matugen image "$wallpaper"
      pkill -USR1 kitty || true
    '';
  };
in
{
  home.packages = [ wallpaper-change ];
  home.activation.cloneWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Pictures"
    if [ ! -d "${config.home.homeDirectory}/Pictures/wallpapers" ]; then
      ${pkgs.git}/bin/git clone https://github.com/robertjarske/wallpapers \
        "${config.home.homeDirectory}/Pictures/wallpapers"
    else
      ${pkgs.git}/bin/git -C "${config.home.homeDirectory}/Pictures/wallpapers" pull --ff-only || true
    fi
  '';

  xdg.configFile."hypr/hyprpaper.conf".text =
    let wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/forest-mountain-cloudy-valley.png";
    in ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
      splash = false
    '';

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      after_sleep_cmd = hyprctl dispatch dpms on
      ignore_dbus_inhibit = false
    }

    listener {
      timeout = 150
      on-timeout = brightnessctl -s set 10
      on-resume = brightnessctl -r
    }

    listener {
      timeout = 150
      on-timeout = brightnessctl -sd rgb:kbd_backlight set 0
      on-resume = brightnessctl -rd rgb:kbd_backlight
    }

    listener {
      timeout = 300
      on-timeout = loginctl lock-session
    }

    listener {
      timeout = 330
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on
    }

    listener {
      timeout = 1800
      on-timeout = systemctl suspend
    }
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ "eDP-1,3840x2400@60,0x0,1.6" ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(cba6f7) rgb(89b4fa) 45deg";
        "col.inactive_border" = "rgb(313244)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      input = {
        kb_layout = "se";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      env = [
        "GTK_THEME,catppuccin-mocha-mauve-standard:dark"

        # Wayland backends
        "GDK_BACKEND,wayland,x11"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"

        # Firefox
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_USE_XINPUT2,1"

        # Cursor
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      "$mod" = "SUPER";

      bind = [
        # Apps
        "$mod, Return, exec, kitty"
        "$mod, E, exec, nautilus"
        "$mod, R, exec, pkill rofi || rofi -show drun -modi drun,calc,filebrowser,run,window"

        # Window management
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod SHIFT, M, exit"
        "$mod SHIFT, R, exec, hyprpanel -q & hyprpanel"

        # Lock screen
        "CTRL ALT, L, exec, pidof hyprlock || hyprlock"

        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Workspaces — switch
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Workspaces — move window
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Scratchpad
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # Wallpaper
        "CTRL ALT, W, exec, wallpaper-change"

        # Screenshots
        ", Print, exec, hyprshot -m output"
        "SHIFT, Print, exec, hyprshot -m region"
        "$mod, Print, exec, hyprshot -m window"

        # Clipboard history picker
        "$mod SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      # bindl: active even when screen is locked
      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", switch:on:Lid Switch, exec, hyprctl dispatch dpms off eDP-1"
        ", switch:off:Lid Switch, exec, hyprctl dispatch dpms on eDP-1"
      ];

      exec-once = [
        "hyprpolkitagent"
        "nm-applet --indicator"
        "yubikey-touch-detector --libnotify"
        "hyprpaper"
        "hypridle"
        "hyprpanel"
        "swaync"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        # Apply random wallpaper and generate Material You colors on login.
        # Small delay ensures hyprpaper is ready to accept IPC commands.
        "bash -c 'sleep 2 && wallpaper-change'"
      ];
    };
  };
}
