{pkgs, ...}: {
  home.packages = [pkgs.wlr-which-key];

  # Config for wlr-which-key — a keybinding reference popup for Hyprland.
  # Triggered by $mod + F1 (see hyprland.nix).
  # Keys mirror actual Hyprland binds where possible for muscle-memory consistency.
  xdg.configFile."wlr-which-key/config.yaml".text = ''
    font: "JetBrainsMono Nerd Font 12"
    background: "#1e1e2eee"
    color: "#cdd6f4"
    border: "#cba6f7"
    separator: " ➜ "
    border_width: 2
    corner_r: 12
    padding: 20
    anchor: center
    rows_per_column: 10
    inhibit_compositor_keyboard_shortcuts: true
    auto_kbd_layout: true

    menu:
      # ── Apps ─────────────────────────────────────────
      - { key: Return, desc: "  Terminal  ($mod+Return)",    cmd: kitty }
      - { key: e,      desc: "  Files     ($mod+E)",         cmd: nautilus }
      - { key: space,  desc: "  Launcher  ($mod+Space)",     cmd: "rofi -show drun -modi drun,filebrowser,run,window" }
      - { key: c,      desc: "  Clipboard ($mod+Shift+V)",   cmd: "cliphist list | rofi -dmenu | cliphist decode | wl-copy" }

      # ── Windows ──────────────────────────────────────
      - { key: q, desc: "  Close      ($mod+Q)", cmd: "hyprctl dispatch killactive" }
      - { key: f, desc: "  Fullscreen ($mod+F)", cmd: "hyprctl dispatch fullscreen" }
      - { key: v, desc: "  Float      ($mod+V)", cmd: "hyprctl dispatch togglefloating" }
      - { key: p, desc: "  Pseudo     ($mod+P)", cmd: "hyprctl dispatch pseudo" }
      - { key: j, desc: "  Split      ($mod+J)", cmd: "hyprctl dispatch togglesplit" }

      # ── Scratchpad ───────────────────────────────────
      - { key: s, desc: "  Scratchpad ($mod+S)", cmd: "hyprctl dispatch togglespecialworkspace magic" }

      # ── Workspaces ───────────────────────────────────
      - key: g
        desc: "  Go to workspace ($mod+1-9,0)"
        submenu:
          - { key: "1", desc: "Workspace 1",  cmd: "hyprctl dispatch workspace 1" }
          - { key: "2", desc: "Workspace 2",  cmd: "hyprctl dispatch workspace 2" }
          - { key: "3", desc: "Workspace 3",  cmd: "hyprctl dispatch workspace 3" }
          - { key: "4", desc: "Workspace 4",  cmd: "hyprctl dispatch workspace 4" }
          - { key: "5", desc: "Workspace 5",  cmd: "hyprctl dispatch workspace 5" }
          - { key: "6", desc: "Workspace 6",  cmd: "hyprctl dispatch workspace 6" }
          - { key: "7", desc: "Workspace 7",  cmd: "hyprctl dispatch workspace 7" }
          - { key: "8", desc: "Workspace 8",  cmd: "hyprctl dispatch workspace 8" }
          - { key: "9", desc: "Workspace 9",  cmd: "hyprctl dispatch workspace 9" }
          - { key: "0", desc: "Workspace 10", cmd: "hyprctl dispatch workspace 10" }

      - key: m
        desc: "  Move window to workspace ($mod+Shift+1-9,0)"
        submenu:
          - { key: "1", desc: "Workspace 1",  cmd: "hyprctl dispatch movetoworkspace 1" }
          - { key: "2", desc: "Workspace 2",  cmd: "hyprctl dispatch movetoworkspace 2" }
          - { key: "3", desc: "Workspace 3",  cmd: "hyprctl dispatch movetoworkspace 3" }
          - { key: "4", desc: "Workspace 4",  cmd: "hyprctl dispatch movetoworkspace 4" }
          - { key: "5", desc: "Workspace 5",  cmd: "hyprctl dispatch movetoworkspace 5" }
          - { key: "6", desc: "Workspace 6",  cmd: "hyprctl dispatch movetoworkspace 6" }
          - { key: "7", desc: "Workspace 7",  cmd: "hyprctl dispatch movetoworkspace 7" }
          - { key: "8", desc: "Workspace 8",  cmd: "hyprctl dispatch movetoworkspace 8" }
          - { key: "9", desc: "Workspace 9",  cmd: "hyprctl dispatch movetoworkspace 9" }
          - { key: "0", desc: "Workspace 10", cmd: "hyprctl dispatch movetoworkspace 10" }

      # ── Screenshots ──────────────────────────────────
      - key: Print
        desc: "  Screenshot (Print variants)"
        submenu:
          - { key: f, desc: "Full output → clipboard + file",   cmd: "bash -c 'mkdir -p $HOME/Pictures/Screenshots && grimblast copysave output $HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'" }
          - { key: a, desc: "Area selection → clipboard + file", cmd: "bash -c 'mkdir -p $HOME/Pictures/Screenshots && grimblast copysave area $HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'" }
          - { key: w, desc: "Active window → clipboard + file",  cmd: "bash -c 'mkdir -p $HOME/Pictures/Screenshots && grimblast copysave active $HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'" }

      # ── System ───────────────────────────────────────
      - { key: l, desc: "  Lock screen    (Ctrl+Alt+L)", cmd: "pidof hyprlock || hyprlock" }
      - { key: w, desc: "  Wallpaper      (Ctrl+Alt+W)", cmd: wallpaper-change }
      - { key: r, desc: "  Restart Panel  ($mod+Shift+R)", cmd: "hyprpanel -q; hyprpanel" }
  '';
}
