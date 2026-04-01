{pkgs, ...}: let
  mdatp = pkgs.callPackage ../../pkgs/mdatp.nix {};

  # Opened as a floating kitty window by mdatp-action.
  # Shows full threat details, copies the encyclopedia URL to clipboard,
  # and lets the user dismiss the threat interactively.
  mdatp-details = pkgs.writeShellApplication {
    name = "mdatp-details";
    runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.wl-clipboard];
    text = ''
      id="$1"
      name="$2"
      type="$3"
      status="$4"
      info_url="$5"

      DISMISSED_FILE="$HOME/.local/state/mdatp-notify/dismissed.json"
      mkdir -p "$HOME/.local/state/mdatp-notify"
      [[ -f "$DISMISSED_FILE" ]] || echo '{}' > "$DISMISSED_FILE"

      # Copy URL to clipboard immediately so it's ready to paste
      printf '%s' "$info_url" | wl-copy 2>/dev/null || true

      clear
      printf '\n'
      printf '  ┌─────────────────────────────────────────────────┐\n'
      printf '  │         Microsoft Defender — Threat Detected     │\n'
      printf '  └─────────────────────────────────────────────────┘\n'
      printf '\n'
      printf '  Name   : %s\n' "$name"
      printf '  Type   : %s\n' "$type"
      printf '  Status : %s\n' "$status"
      printf '  ID     : %s\n' "$id"
      printf '\n'
      printf '  Encyclopedia URL (copied to clipboard):\n'
      printf '  %s\n' "$info_url"
      printf '\n'
      printf '  ─────────────────────────────────────────────────────\n'
      printf '  [D] Dismiss this threat   [Q / any key] Close\n'
      printf '  ─────────────────────────────────────────────────────\n'
      printf '\n'

      read -r -n1 -s key
      if [[ "''${key,,}" == "d" ]]; then
        jq --arg id "$id" --arg name "$name" '. + {($id): $name}' "$DISMISSED_FILE" \
          > "$DISMISSED_FILE.tmp"
        mv "$DISMISSED_FILE.tmp" "$DISMISSED_FILE"
        printf '\n  Dismissed. Notifications suppressed until: mdatp-notify undismiss\n\n'
        sleep 2
      fi
    '';
  };

  # Handles notification action button clicks.
  # Launched as a transient systemd-run unit per threat by mdatp-check.
  mdatp-action = pkgs.writeShellApplication {
    name = "mdatp-action";
    runtimeInputs = [pkgs.jq pkgs.libnotify pkgs.coreutils pkgs.kitty];
    text = ''
      id="$1"
      name="$2"
      type="$3"
      status="$4"
      info_url="$5"
      replace_id="$6"

      DISMISSED_FILE="$HOME/.local/state/mdatp-notify/dismissed.json"
      mkdir -p "$HOME/.local/state/mdatp-notify"
      [[ -f "$DISMISSED_FILE" ]] || echo '{}' > "$DISMISSED_FILE"

      body=$(printf "%s\n\nType: %s | Status: %s\n\nClick Details for more information." \
        "$name" "$type" "$status")

      # Use simple labels (no key:label colon) to avoid swaync display issues.
      # notify-send --wait prints the label when the user clicks a button.
      action=$(notify-send \
        -u critical \
        -i dialog-warning \
        -r "$replace_id" \
        --action="Details" \
        --action="Dismiss" \
        --wait \
        "Microsoft Defender — Threat Detected" "$body" 2>/dev/null) || exit 0

      # swaync returns the 0-based button index, not the label string
      case "$action" in
        0)
          kitty \
            --class mdatp-details \
            --title "Defender — Threat Details" \
            ${mdatp-details}/bin/mdatp-details \
            "$id" "$name" "$type" "$status" "$info_url"
          ;;
        1)
          jq --arg id "$id" --arg name "$name" '. + {($id): $name}' "$DISMISSED_FILE" \
            > "$DISMISSED_FILE.tmp"
          mv "$DISMISSED_FILE.tmp" "$DISMISSED_FILE"
          notify-send -u low -i dialog-information \
            "Microsoft Defender" "Dismissed: $name" || true
          ;;
      esac
    '';
  };

  # Called by the systemd timer. For each active non-dismissed threat, launches
  # a transient mdatp-action unit if one isn't already waiting.
  mdatp-check = pkgs.writeShellApplication {
    name = "mdatp-check";
    runtimeInputs = [pkgs.jq pkgs.libnotify pkgs.coreutils mdatp];
    text = ''
      STATE_DIR="$HOME/.local/state/mdatp-notify"
      DISMISSED_FILE="$STATE_DIR/dismissed.json"
      HAD_THREATS_FLAG="$STATE_DIR/had-threats"
      mkdir -p "$STATE_DIR"
      [[ -f "$DISMISSED_FILE" ]] || echo '{}' > "$DISMISSED_FILE"

      threats_json=$(mdatp threat list --output json 2>/dev/null) || exit 0
      threat_count=$(printf '%s' "$threats_json" | jq '[.threats.scans[].threats[]] | length')

      if [[ "$threat_count" -eq 0 ]]; then
        if [[ -f "$HAD_THREATS_FLAG" ]]; then
          rm -f "$HAD_THREATS_FLAG"
          notify-send -u normal -i dialog-information \
            "Microsoft Defender" "Back to normal — no threats detected." || true
        fi
        exit 0
      fi

      touch "$HAD_THREATS_FLAG"

      # Discover the active Wayland display for this user session
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      wayland_display=$(find "$runtime_dir" -maxdepth 1 -name 'wayland-*' 2>/dev/null \
        | head -1 | xargs -I{} basename {} 2>/dev/null || printf 'wayland-1')

      while IFS= read -r threat; do
        id=$(printf '%s' "$threat" | jq -r '.tracking_id')
        name=$(printf '%s' "$threat" | jq -r '.name')
        type=$(printf '%s' "$threat" | jq -r '.type')
        status=$(printf '%s' "$threat" | jq -r '.status')

        dismissed=$(jq -r --arg id "$id" '.[$id] // empty' "$DISMISSED_FILE")
        [[ -n "$dismissed" ]] && continue

        replace_id=$(( $(printf '%s' "$id" | cksum | cut -d' ' -f1) % 2147483647 ))
        encoded_name=$(printf '%s' "$name" | jq -sRr @uri)
        info_url="https://www.microsoft.com/en-us/wdsi/threats/malware-encyclopedia-description?Name=$encoded_name"

        unit="mdatp-threat-''${replace_id}"

        # Stop and reset any existing unit with this name so systemd-run can
        # reuse it. The notify-send replace-id updates the notification in place.
        /run/current-system/sw/bin/systemctl --user stop "''${unit}.service" 2>/dev/null || true
        /run/current-system/sw/bin/systemctl --user reset-failed "''${unit}.service" 2>/dev/null || true
        /run/current-system/sw/bin/systemd-run \
          --user --no-block \
          --unit="''${unit}" \
          --setenv=HOME="$HOME" \
          --setenv=DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
          --setenv=XDG_RUNTIME_DIR="$runtime_dir" \
          --setenv=WAYLAND_DISPLAY="$wayland_display" \
          -- ${mdatp-action}/bin/mdatp-action \
          "$id" "$name" "$type" "$status" "$info_url" "$replace_id"
      done < <(printf '%s' "$threats_json" | jq -c '.threats.scans[].threats[].threat')
    '';
  };

  # User-facing management CLI.
  # Usage: mdatp-notify <status|dismiss <id>|undismiss>
  mdatp-notify = pkgs.writeShellApplication {
    name = "mdatp-notify";
    runtimeInputs = [pkgs.jq pkgs.coreutils mdatp];
    text = ''
      STATE_DIR="$HOME/.local/state/mdatp-notify"
      DISMISSED_FILE="$STATE_DIR/dismissed.json"
      mkdir -p "$STATE_DIR"
      [[ -f "$DISMISSED_FILE" ]] || echo '{}' > "$DISMISSED_FILE"

      cmd="''${1:-}"

      case "$cmd" in
        dismiss)
          id="''${2:-}"
          if [[ -z "$id" ]]; then
            echo "Usage: mdatp-notify dismiss <threat-id>" >&2
            exit 1
          fi
          name=$(mdatp threat list --output json 2>/dev/null \
            | jq -r --arg id "$id" \
                '[.threats.scans[].threats[].threat]
                 | map(select(.tracking_id == $id))
                 | first | .name // "unknown"')
          jq --arg id "$id" --arg name "$name" '. + {($id): $name}' "$DISMISSED_FILE" \
            > "$DISMISSED_FILE.tmp"
          mv "$DISMISSED_FILE.tmp" "$DISMISSED_FILE"
          echo "Dismissed: ''${name:-$id}"
          ;;

        undismiss)
          echo '{}' > "$DISMISSED_FILE"
          echo "Cleared all dismissed threats — notifications will resume on next poll."
          ;;

        status)
          threats_json=$(mdatp threat list --output json 2>/dev/null) || {
            echo "Could not reach mdatp daemon." >&2
            exit 1
          }
          threat_count=$(printf '%s' "$threats_json" | jq '[.threats.scans[].threats[]] | length')
          dismissed_count=$(jq 'length' "$DISMISSED_FILE")

          echo "Active threats: $threat_count"
          echo "Dismissed:      $dismissed_count"

          if [[ "$threat_count" -gt 0 ]]; then
            echo ""
            printf '%s' "$threats_json" \
              | jq -r '.threats.scans[].threats[].threat
                  | "  [\(.tracking_id)] \(.name) [\(.type)] — \(.status)"'
          fi

          if [[ "$dismissed_count" -gt 0 ]]; then
            echo ""
            echo "Dismissed threats:"
            jq -r 'to_entries[] | "  [\(.key)] \(.value)"' "$DISMISSED_FILE"
          fi
          ;;

        *)
          echo "Usage: mdatp-notify <status|dismiss <id>|undismiss>" >&2
          exit 1
          ;;
      esac
    '';
  };
in {
  home.packages = [mdatp-notify pkgs.libnotify];

  systemd.user.services.mdatp-notify = {
    Unit.Description = "Check Microsoft Defender threats and send desktop notifications";
    Service = {
      Type = "oneshot";
      ExecStart = "${mdatp-check}/bin/mdatp-check";
      Environment = ["DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus"];
    };
  };

  systemd.user.timers.mdatp-notify = {
    Unit.Description = "Poll Microsoft Defender for threats every 5 minutes";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
    Install.WantedBy = ["timers.target"];
  };
}
