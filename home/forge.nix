{
  pkgs,
  unstable,
  lib,
  ...
}: let
  # Rearranges Hyprland workspaces to match the active kanshi monitor profile.
  # Called from kanshi exec after each profile switch.
  hypr-workspace-layout = pkgs.writeShellScript "hypr-workspace-layout" ''
    # Debounce: kanshi fires this exec once per monitor that appears during dock
    # enumeration (e.g. DP-5 appears → "no profile matched", DP-6 appears → "home"
    # matched). Only the last invocation in a burst should run; earlier ones bail out.
    # Token is this process's PID; any newer invocation overwrites it.
    token_file="/tmp/hypr-workspace-layout-token"
    echo "$$" > "$token_file"
    sleep 2
    [ "$(cat "$token_file" 2>/dev/null)" = "$$" ] || exit 0

    # Set the default-monitor rule AND move any already-created workspace.
    bind() {
      local ws="$1" mon="$2"
      hyprctl keyword workspace "$ws, monitor:$mon" >/dev/null 2>&1
      hyprctl dispatch moveworkspacetomonitor "$ws" "$mon" >/dev/null 2>&1
    }

    # Poll until a monitor is listed in hyprctl output (up to 10 s).
    # Needed because kanshi fires the exec right after sending the wlr-output-management
    # commands, but the GPU may need extra time to light up Thunderbolt-tunneled DP outputs.
    wait_for_monitor() {
      local mon="$1"
      for i in $(seq 1 20); do
        hyprctl monitors | grep -q "^Monitor $mon " && return 0
        sleep 0.5
      done
      echo "hypr-workspace-layout: timed out waiting for $mon" >&2
      return 1
    }

    case "$1" in
      work)
        # 4 monitors left→right: eDP-1, DP-6, DP-7, DP-8
        wait_for_monitor DP-6 && wait_for_monitor DP-7 && wait_for_monitor DP-8 || exit 1
        # Force DPMS on in case the GPU missed the hotplug signal at boot.
        hyprctl dispatch dpms on DP-6 >/dev/null 2>&1
        hyprctl dispatch dpms on DP-7 >/dev/null 2>&1
        hyprctl dispatch dpms on DP-8 >/dev/null 2>&1
        bind 1 DP-6; bind 2 DP-6; bind 3 DP-6; bind 4 DP-6
        bind 5 DP-7; bind 6 DP-7; bind 7 DP-7; bind 8 DP-7
        bind 9 DP-8; bind 10 DP-8
        # Move Teams to workspace 9 (DP-8) if it is already running.
        hyprctl dispatch movetoworkspacesilent "9,class:^(teams-for-linux)$" >/dev/null 2>&1 || true
        ;;
      home)
        # 3 monitors left→right: eDP-1, DP-5, DP-6
        wait_for_monitor DP-5 && wait_for_monitor DP-6 || exit 1
        hyprctl dispatch dpms on DP-5 >/dev/null 2>&1
        hyprctl dispatch dpms on DP-6 >/dev/null 2>&1
        bind 9 eDP-1; bind 10 eDP-1
        bind 1 DP-5; bind 2 DP-5; bind 3 DP-5; bind 4 DP-5
        bind 5 DP-6; bind 6 DP-6; bind 7 DP-6; bind 8 DP-6
        ;;
      laptop)
        # Single monitor: all workspaces on eDP-1.
        for ws in 1 2 3 4 5 6 7 8 9 10; do bind "$ws" eDP-1; done
        ;;
    esac
  '';
in {
  imports = [
    ./common/zsh.nix
    ./common/kitty.nix
    ./common/starship.nix
    ./common/git.nix
    ./common/neovim.nix
    ./common/gtk.nix
    ./common/qt.nix
    ./common/hyprland.nix
    ./common/rofi.nix
    ./common/matugen.nix
    ./common/hyprpanel.nix
    ./common/work-certs.nix
    ./common/fastfetch.nix
    ./common/wlr-which-key.nix
    ./common/ssh.nix
    ./common/vscode.nix
    ./common/mpv.nix
    ./common/direnv.nix
    ./common/xdg.nix
    ./common/yubikey.nix
    ./common/mdatp-notify.nix
    ./common/wayle.nix
  ];

  programs = {
    # Work SSH hosts live in a locally-managed file, not tracked in git.
    # On first setup, create ~/.config/ssh/work-hosts with ControlMaster entries
    # for internal GitLab and any other work hosts, e.g.:
    #   Host <internal-gitlab-host>
    #     ControlMaster auto
    #     ControlPath ~/.ssh/cm-%r@%h:%p
    #     ControlPersist 10m
    ssh.extraConfig = "Include ~/.config/ssh/work-hosts";

    zsh.shellAliases = {
      # Hostname is arch-serobja but flake attribute stays forge — override here.
      nrs = lib.mkForce "nh os switch ~/code/nix-dots --hostname forge";
      nrt = lib.mkForce "nh os test ~/code/nix-dots --hostname forge";

      apps = "cd ~/code/applications";
      core = "cd ~/code/core";
      common = "cd ~/code/common";
      socket-server = "cd ~/code/socket-server";
      sniffer = "cd ~/code/phpcs-community/vscode-php-sniffer";
      buildserver = "s buildserver";
      docker-server = "s docker-server";
      docker-server2 = "s docker-server2";
      docker-server3 = "s docker-server3";
      prod = "s prod";
      gitlab = "s gitlab";

      # Playwright — enter dev shell with NixOS-compatible browsers
      pw = "nix develop ~/code/nix-dots#playwright";
    };

    # Identity + signing key loaded from a locally-managed file, not tracked in this repo.
    # On first setup:
    #   printf '[user]\n  name = ...\n  email = ...\n  signingKey = YOUR_GPG_KEY_ID\n' \
    #     > ~/.config/git/local-identity
    git.includes = [
      {path = "~/.config/git/local-identity";}
    ];
  };

  wayland.windowManager.hyprland = {
    settings = {
      # Monitor layout and workspace placement are managed by kanshi.
      # The catch-all from hyprland.nix covers any output not matched by a profile.

      # Teams for Linux always opens on workspace 5 (second external monitor)
      # Hyprland 0.53+ requires match:class prefix (old class: syntax removed)
      windowrule = [
        "workspace 5 silent, match:class ^(teams-for-linux)$"
        "workspace 6 silent, match:class ^(vivaldi-stable)$"
        "float 1, match:class ^(mdatp-details)$"
        "size 760 380, match:class ^(mdatp-details)$"
        "center 1, match:class ^(mdatp-details)$"
      ];

      exec-once = [
        "vivaldi"
        "teams-for-linux"
      ];
    };
  };

  # Kanshi — automatic output profile switching via wlr-output-management.
  # Port names are used (not descriptions) — wlr-output-management sends
  # descriptions in a different format than hyprctl reports them.
  # Each profile's exec rearranges workspaces after the layout is applied.
  services.kanshi.enable = true;
  xdg = {
    # Default changed in HM 26.05; set explicitly to keep XDG dirs in the session environment.
    userDirs.setSessionVariables = true;
    configFile."kanshi/config".text = ''
      profile work {
        output eDP-1 mode 3200x2000@60 position 0,0 scale 1.6
        output DP-6 mode 2560x1440@59.95 position 2000,0 scale 1.0
        output DP-7 mode 2560x1440@59.95 position 4560,0 scale 1.0
        output DP-8 mode 2560x1440@59.95 position 7120,0 scale 1.0
        exec ${hypr-workspace-layout} work
      }

      profile home {
        output eDP-1 mode 3200x2000@120 position 0,0 scale 2.0
        output DP-5 mode 2560x1440@75 position 1600,0 scale 1.0
        output DP-6 mode 2560x1440@75 position 4160,0 scale 1.0
        exec ${hypr-workspace-layout} home
      }

      profile laptop {
        output eDP-1 mode 3200x2000@120 position 0,0 scale 2.0
        exec ${hypr-workspace-layout} laptop
      }
    '';
  };

  # Azure Data Studio (VS Code-based) reads argv.json before starting.
  # Same gnome-libsecret fix as VS Code.
  home = {
    file.".config/azuredatastudio/argv.json" = {
      text = builtins.toJSON {"password-store" = "gnome-libsecret";};
      force = true;
    };

    packages = [
      unstable.onlyoffice-desktopeditors
      unstable.zed-editor
      pkgs.qalculate-gtk
    ];

    stateVersion = "25.11";
  };
}
