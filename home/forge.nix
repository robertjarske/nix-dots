{pkgs, ...}: {
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
  ];

  programs = {
    # Work SSH hosts live in a locally-managed file, not tracked in git.
    ssh.extraConfig = "Include ~/.config/ssh/work-hosts";

    zsh.shellAliases = {
      nvdriver = "nvidia-smi --query-gpu=driver_version --format=csv,noheader";
      nvkernel = "uname -r";
      btop = "LD_LIBRARY_PATH=/run/opengl-driver/lib ${pkgs.btop}/bin/btop";

      apps = "cd ~/code/applications";
      core = "cd ~/code/core";
      common = "cd ~/code/common";
      socket-server = "cd ~/code/socket-server";
      buildserver = "s buildserver";
      docker-server = "s docker-server";
      docker-server2 = "s docker-server2";
      docker-server3 = "s docker-server3";
      prod = "s prod";
      gitlab = "s gitlab";
    };

    # Identity (name + work email) loaded from a locally-managed file, not tracked in this repo.
    # On first setup: printf '[user]\n  name = ...\n  email = ...\n' > ~/.config/git/local-identity
    git.includes = [
      {path = "~/.config/git/local-identity";}
    ];
  };

  wayland.windowManager.hyprland = {
    extraConfig = ''
      env = LIBVA_DRIVER_NAME,nvidia
      env = GBM_BACKEND,nvidia-drm
      env = __GLX_VENDOR_LIBRARY_NAME,nvidia
      env = NVD_BACKEND,direct
    '';
    settings = {
      # NVIDIA: let Hyprland auto-detect whether hardware cursors work.
      # Replaces the legacy WLR_NO_HARDWARE_CURSORS env var.
      # 0 = force hardware, 1 = force software, 2 = auto (recommended for NVIDIA)
      cursor.no_hardware_cursors = 2;
      monitor = [
        "eDP-1,3200x2000@120,0x0,2"
        "DP-5,2560x1440@75,1600x0,1"
        "DP-6,2560x1440@75,4160x0,1"
      ];
      # Workspace → monitor assignments matching the 3-monitor layout.
      # DP-5 (left): 1-4, DP-6 (right): 5-8, eDP-1 (laptop): 9-10
      workspace = [
        "1,monitor:DP-5,default:true"
        "2,monitor:DP-5"
        "3,monitor:DP-5"
        "4,monitor:DP-5"
        "5,monitor:DP-6,default:true"
        "6,monitor:DP-6"
        "7,monitor:DP-6"
        "8,monitor:DP-6"
        "9,monitor:eDP-1,default:true"
        "10,monitor:eDP-1"
      ];
      # Teams for Linux always opens on workspace 5 (right external monitor)
      # Hyprland 0.53+ requires match:class prefix (old class: syntax removed)
      windowrule = ["workspace 5 silent, match:class ^(teams-for-linux)$"];

      exec-once = [
        "[workspace 6 silent] vivaldi"
        "[workspace 5 silent] teams-for-linux"
      ];
    };
  };

  # Azure Data Studio (VS Code-based) reads argv.json before starting.
  # Same gnome-libsecret fix as VS Code.
  home.file.".config/azuredatastudio/argv.json" = {
    text = builtins.toJSON {"password-store" = "gnome-libsecret";};
    force = true;
  };

  home.stateVersion = "25.11";
}
