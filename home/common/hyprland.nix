{
  config,
  pkgs,
  lib,
  unstable,
  hyprpanel,
  ...
}: let
  # Solid Catppuccin Mocha base (#1e1e2e) shown immediately on login via swww
  # before wallpaper-restore fades in the real wallpaper. Always in the Nix store.
  fallbackWallpaper =
    pkgs.runCommand "fallback-wallpaper.png" {
      nativeBuildInputs = [pkgs.imagemagick];
    } ''
      convert -size 1920x1080 xc:'#1e1e2e' "$out"
    '';

  # Listens on Hyprland's event socket and re-runs wallpaper-restore whenever a
  # monitor is added. This fixes dock monitors not getting a wallpaper on login
  # (Thunderbolt enumeration is slower than the initial 2-second delay).
  wallpaper-monitor-listener = pkgs.writeShellApplication {
    name = "wallpaper-monitor-listener";
    runtimeInputs = [pkgs.socat];
    text = ''
      # Wait until the Hyprland socket is available.
      until [ -S "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" ]; do
        sleep 0.5
      done

      socat -u \
        UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" \
        - | while IFS= read -r line; do
          if [[ "$line" == monitoradded* ]]; then
            # Brief delay for the monitor to be fully initialized before applying.
            sleep 1
            wallpaper-restore
          fi
        done
    '';
  };

  # Restores the last-used wallpaper from ~/.config/hypr/current_wallpaper on login
  # and whenever a new monitor is connected. Falls back to a random pick on first run.
  # Does NOT pull git or acquire a lock — kept lightweight for startup use.
  # swww img waits for the daemon internally so no explicit delay is needed.
  wallpaper-restore = pkgs.writeShellApplication {
    name = "wallpaper-restore";
    runtimeInputs = [unstable.awww pkgs.matugen hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default];
    text = ''
      current_file="$HOME/.config/hypr/current_wallpaper"
      wallpaper=""

      if [ -f "$current_file" ]; then
        saved=$(cat "$current_file")
        [ -f "$saved" ] && wallpaper="$saved"
      fi

      # First run — no saved wallpaper yet. Pick random and persist it.
      if [ -z "$wallpaper" ]; then
        wallpapers_dir="$HOME/Pictures/wallpapers"
        [ -d "$wallpapers_dir" ] || exit 0
        wallpaper=$(find "$wallpapers_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n1)
        [ -n "$wallpaper" ] || exit 0
        mkdir -p "$(dirname "$current_file")"
        printf '%s' "$wallpaper" > "$current_file"
      fi

      awww img "$wallpaper" --transition-type fade --transition-duration 1
      ln -sf "$wallpaper" "$HOME/.config/rofi/.current_wallpaper"
      matugen --source-color-index 0 image "$wallpaper"
      matugen --source-color-index 0 --type scheme-expressive -c "$HOME/.config/matugen/config-hyprpanel.toml" image "$wallpaper"
      pkill -USR1 kitty || true
      hyprpanel useTheme "$HOME/.config/ags/hyprpanel-matugen-theme.json" || true
    '';
  };

  # Picks a new random wallpaper, saves it as the current, and applies it with a fade.
  # Keybind: CTRL+ALT+W — call this when you want to change wallpaper.
  wallpaper-change = pkgs.writeShellApplication {
    name = "wallpaper-change";
    runtimeInputs = [unstable.awww pkgs.matugen pkgs.util-linux pkgs.git hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default];
    text = ''
      # Prevent concurrent runs — rapid invocations would run matugen in parallel.
      exec 9>/tmp/wallpaper-change.lock
      flock -n 9 || exit 0

      wallpapers_dir="$HOME/Pictures/wallpapers"

      # Self-heal: clone on first login, pull on subsequent logins.
      # Activation-time sync (syncWallpapers) is the authoritative path on
      # rebuilds; this catches cases where that clone failed (e.g. offline).
      if [ ! -d "$wallpapers_dir" ]; then
        mkdir -p "$(dirname "$wallpapers_dir")"
        git clone https://github.com/robertjarske/wallpapers "$wallpapers_dir" \
          || { echo "wallpaper-change: clone failed"; exit 0; }
      else
        git -C "$wallpapers_dir" pull --ff-only 2>/dev/null || true
      fi

      history_file="$HOME/.config/hypr/wallpaper_history"
      all=$(find "$wallpapers_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))
      total=$(echo "$all" | wc -l)

      # Exclude the last third of the collection from the candidate pool so
      # recently shown wallpapers are skipped. Fall back to the full list if
      # everything has been excluded (e.g. tiny collection).
      exclude=$((total / 3))
      candidates="$all"
      if [ "$exclude" -gt 0 ] && [ -f "$history_file" ]; then
        filtered=$(echo "$all" | grep -vxF "$(tail -n "$exclude" "$history_file")" || true)
        [ -n "$filtered" ] && candidates="$filtered"
      fi

      wallpaper=$(echo "$candidates" | shuf -n1)
      [ -n "$wallpaper" ] || exit 0

      # Append to history and keep it bounded to the collection size.
      echo "$wallpaper" >> "$history_file"
      tmp=$(mktemp)
      tail -n "$total" "$history_file" > "$tmp" && mv "$tmp" "$history_file"

      # Persist so wallpaper-restore can reapply on next login.
      current_file="$HOME/.config/hypr/current_wallpaper"
      mkdir -p "$(dirname "$current_file")"
      printf '%s' "$wallpaper" > "$current_file"

      awww img "$wallpaper" --transition-type fade --transition-duration 1
      ln -sf "$wallpaper" "$HOME/.config/rofi/.current_wallpaper"
      matugen --source-color-index 0 image "$wallpaper"
      matugen --source-color-index 0 --type scheme-expressive -c "$HOME/.config/matugen/config-hyprpanel.toml" image "$wallpaper"
      pkill -USR1 kitty || true
      hyprpanel useTheme "$HOME/.config/ags/hyprpanel-matugen-theme.json" || true
    '';
  };
in {
  home = {
    packages = [wallpaper-change wallpaper-restore wallpaper-monitor-listener];
    activation = {
      # Catppuccin Mocha fallback so `source` doesn't error on first boot before
      # matugen has run. Only the variables actually used in the config are needed.
      hyprlandColorsFallback = lib.hm.dag.entryAfter ["writeBoundary"] ''
            colors_file="${config.home.homeDirectory}/.config/hypr/matugen/matugen-hyprland.conf"
            if [ ! -f "$colors_file" ]; then
              mkdir -p "$(dirname "$colors_file")"
              cat > "$colors_file" << 'EOF'
        $primary = rgba(cba6f7ff)
        $tertiary = rgba(94e2d5ff)
        $outline_variant = rgba(313244ff)
        EOF
            fi
      '';
      syncWallpapers = lib.hm.dag.entryAfter ["writeBoundary"] ''
        wallpapers_dir="${config.home.homeDirectory}/Pictures/wallpapers"
        mkdir -p "$(dirname "$wallpapers_dir")"
        if [ -d "$wallpapers_dir" ]; then
          ${pkgs.git}/bin/git -C "$wallpapers_dir" pull --ff-only \
            || echo "wallpaper-sync: git pull failed (offline?), using cached wallpapers"
        else
          ${pkgs.git}/bin/git clone https://github.com/robertjarske/wallpapers "$wallpapers_dir" \
            || echo "wallpaper-sync: initial clone failed (offline?), hyprpaper fallback will be used until next rebuild with network"
        fi
      '';
    };
  };

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
    package = unstable.hyprland;
    # UWSM manages graphical-session.target activation; disabling home-manager's
    # own systemd integration avoids a double-activation conflict.
    systemd.enable = false;
    settings = {
      # Catch-all: any monitor not matched by a host-specific rule gets its
      # preferred resolution, auto-placed, at scale 1.
      monitor = [",preferred,auto,1"];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "$primary $tertiary 45deg";
        "col.inactive_border" = "$outline_variant";
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
        numlock_by_default = true;
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

      # Blur rofi's transparent overlay so the blurred desktop shows through.
      # Hyprland 0.53+ syntax: "rule on, match:namespace <name>"
      layerrule = ["blur on, match:namespace rofi"];

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

      "source" = ["~/.config/hypr/matugen/matugen-hyprland.conf"];

      "$mod" = "SUPER";

      bind = [
        # Apps
        "$mod, Return, exec, kitty"
        "$mod, E, exec, nautilus"
        "$mod, Space, exec, pkill rofi || rofi -show drun -modi drun,filebrowser,run,window"

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

        # Screenshots — grimblast copies to clipboard AND saves to ~/Pictures/Screenshots/
        ", Print, exec, bash -c 'mkdir -p $HOME/Pictures/Screenshots && grimblast copysave output $HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'"
        "SHIFT, Print, exec, bash -c 'mkdir -p $HOME/Pictures/Screenshots && grimblast copysave area $HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'"
        "$mod, Print, exec, bash -c 'mkdir -p $HOME/Pictures/Screenshots && grimblast copysave active $HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'"

        # Clipboard history picker
        "$mod SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        # Keybinding reference popup (slash = Shift+7 on Swedish layout, conflicts with workspace move)
        "$mod, F1, exec, wlr-which-key"
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
        "uwsm app -- ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "uwsm app -- udiskie --tray"
        "uwsm app -- nm-applet --indicator"
        "uwsm app -- yubikey-touch-detector --libnotify"
        "uwsm app -- hypridle"
        "uwsm app -- wl-paste --type text --watch cliphist store"
        "uwsm app -- wl-paste --type image --watch cliphist store"
        # awww-daemon is managed by a systemd user service (see below) so it
        # auto-restarts on crash. awww img waits for the socket internally.
        # One-shot setup script — no persistent cgroup needed.
        "bash -c 'awww img ${fallbackWallpaper} && wallpaper-restore'"
        # Re-apply wallpaper to any monitor added after login (e.g. dock).
        "uwsm app -- wallpaper-monitor-listener"
      ];
    };
  };

  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "swww wallpaper daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${unstable.awww}/bin/awww-daemon";
      # Prefix with '-' so a failure here (e.g. socket not ready on first boot)
      # does not fail the service. Initial wallpaper is set by exec-once; this
      # only matters for daemon restarts where the socket already exists.
      ExecStartPost = "-${wallpaper-restore}/bin/wallpaper-restore";
      Restart = "always";
      RestartSec = "3s";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
