{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- Modern core utils ---
    eza # modern ls
    bat # modern cat
    fd # modern find
    xcp # modern cp
    moreutils # sponge etc.
    jq # json processing
    unzip # extracting .zip archives
    p7zip # extracting .7z, .xz, .rar, .tar.xz, and more
    dive # docker image explorer

    # --- Search / fuzzy ---
    ripgrep # fast grep (also used by neovim telescope)
    fzf # fuzzy finder

    # --- System monitoring ---
    btop # top replacement
    dust # intuitive du
    ncdu # ncurses du

    # --- Network utils ---
    nmap # network scanner
    whois # domain lookup
    rsync # file sync

    # --- Misc CLI ---
    bc # calculator
    navi # interactive cheatsheet
    lazygit # git TUI
    lazydocker # docker TUI
  ];

  programs = {
    bat = {
      enable = true;
      config = {
        theme = "Dracula";
        tabs = "2";
      };
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;

      oh-my-zsh = {
        enable = true;
        plugins = ["git"]; # provides gwip (used in wip alias)
        # No theme — starship handles the prompt
      };

      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        share = true;
      };

      plugins = [
        # fzf-tab must come before autosuggestions/syntax-highlighting
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.zsh";
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
          file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
        }
      ];

      sessionVariables = {
        EDITOR = "nvim";
      };

      shellAliases = {
        # --- Core tools ---
        vim = "nvim";
        ls = "eza --icons -a --group-directories-first";
        lsa = "eza -la --git --group-directories-first";
        tree = "eza --icons -a --group-directories-first --tree --level=3";
        cat = "bat";
        cp = "xcp";

        # --- Docker ---
        dps = "docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'";

        # --- Git quick-fire ---
        asd = "git add . && git commit -m 'asd' && git push";
        wip = "gwip && git push";
        fix = "git add . && git commit -m 'fix' && git push";
        gempty = "git commit --allow-empty --allow-empty-message -m '' && git push";

        dots = "cd ~/code/nix-dots";

        # kitten ssh preserves the kitty terminal protocol over SSH
        s = "kitten ssh";

        # --- Snapper / @home snapshots ---
        snaps = "snapper -c home list"; # list all home snapshots

        # --- Distrobox ---
        db-list = "distrobox list";
        db-enter = "distrobox enter";
        db-rm = "distrobox rm";

        # --- YubiKey ---
        yk-switch = "gpg-connect-agent \"SCD KILLSCD\" /bye; sleep 1 && gpg-connect-agent \"scd serialno\" \"learn --force\" /bye"; # re-associate GPG stubs after swapping YubiKeys
        yk-ssh-load = "cd ~/.ssh && ssh-keygen -K"; # export resident SSH keys from plugged-in YubiKey to ~/.ssh/

        # --- Nix dev shells ---
        ds = "nix develop"; # enter current project's dev shell
        nsh = "nix shell"; # quick: nix shell nixpkgs#foo

        # --- Nix system management ---
        nrs = "nh os switch ~/code/nix-dots"; # build + switch, shows package diff
        nrt = "nh os test ~/code/nix-dots"; # switch without adding to boot menu
        nfu = "cd ~/code/nix-dots && nix flake update"; # update all flake inputs
        ngen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        ngc = "nh clean all"; # remove old generations + gc
        nss = "nh search";

        # --- Config quick-open ---
        zsh_config = "nvim ~/code/nix-dots/home/common/zsh.nix";
        kitty_config = "nvim ~/code/nix-dots/home/common/kitty.nix";
        aa = "nvim ~/code/nix-dots/home/common/zsh.nix";
        reload = "source ~/.zshrc";
        vim_config = "nvim ~/.config/nvim";
      };

      initContent = ''
        # --- Autosuggestion color (default fg=8 is too dim) ---
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ffff00,bg=#808000,bold,underline"

        # --- fzf-tab: subcommand descriptions on Tab (git, docker, systemctl, etc.) ---
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':fzf-tab:*' switch-group '<' '>'

        # --- Word navigation: Ctrl+Left/Right jump words rather than deleting ---
        # Kitty sends \e[1;5D (left) and \e[1;5C (right) for Ctrl+arrow.
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word

        # --- Extra PATH for local tooling ---
        export PATH="$HOME/.config/composer/vendor/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="$HOME/.npm-global/bin:$PATH"

        # --- Dev shell template initializer ---
        # Usage: dsinit [template]   available: default, node, php, python
        dsinit() {
          local tpl="''${1:-default}"
          nix flake init -t ~/code/nix-dots#"$tpl"
        }

        # --- Snapper helpers ---
        # Snapshots live at /home/.snapshots/N/snapshot/$USER/

        # Show which files changed between two snapshots (like git status).
        # Usage: snap-status <from> <to>   e.g. snap-status 5 8
        snap-status() {
          local from="''${1:?Usage: snap-status <from-snapshot> <to-snapshot>}"
          local to="''${2:?Usage: snap-status <from-snapshot> <to-snapshot>}"
          snapper -c home status "$from..$to"
        }

        # List the contents of a snapshot (at an optional subpath relative to $HOME).
        # Usage: snap-ls <N> [relative/path]   e.g. snap-ls 5   or   snap-ls 5 .config
        snap-ls() {
          local n="''${1:?Usage: snap-ls <snapshot-number> [relative-path]}"
          local subpath="''${2:-}"
          ls "/home/.snapshots/$n/snapshot/$USER/''${subpath}"
        }

        # Restore a file or directory from snapshot N to its current location.
        # Usage: snap-restore <N> <relative/path/from/home>
        # e.g.   snap-restore 5 .config/hypr/hyprland.conf
        snap-restore() {
          local n="''${1:?Usage: snap-restore <snapshot-number> <path-relative-to-home>}"
          local relpath="''${2:?Usage: snap-restore <snapshot-number> <path-relative-to-home>}"
          local src="/home/.snapshots/$n/snapshot/$USER/$relpath"
          local dst="$HOME/$relpath"
          if [ ! -e "$src" ]; then
            echo "Error: '$relpath' not found in snapshot $n"
            return 1
          fi
          echo "Restoring: $src"
          echo "       to: $dst"
          cp -ri "$src" "$dst"
        }

        # --- Distrobox helpers ---
        # Usage: db-new <name> <image>   e.g. db-new ubuntu ubuntu:22.04
        db-new() {
          local name="''${1:?Usage: db-new <name> <image>}"
          local image="''${2:?Usage: db-new <name> <image>}"
          distrobox create --name "$name" --image "$image"
        }

        db-help() {
          echo "distrobox — run any Linux distro as a container on NixOS"
          echo ""
          echo "  db-list                      list all containers"
          echo "  db-enter <name>              enter container shell"
          echo "  db-new <name> <image>        create container"
          echo "    e.g. db-new ubuntu ubuntu:22.04"
          echo "    e.g. db-new arch archlinux:latest"
          echo "  db-rm <name>                 remove container"
          echo ""
          echo "  Inside the container:"
          echo "    distrobox-export --app <app>   expose a GUI app to the host"
          echo "    distrobox-export --bin <path>  expose a binary to the host"
          echo ""
          echo "  Uses Podman under the hood (no root needed)."
        }

        # --- nix-ld ---
        nixld-help() {
          echo "nix-ld — run pre-compiled (FHS) Linux binaries on NixOS"
          echo ""
          echo "  Just run the binary directly. nix-ld patches the dynamic linker"
          echo "  so standard ELF binaries work without modification."
          echo ""
          echo "  If a binary still fails (missing libs not in the default set):"
          echo "    nix shell nixpkgs#steam-run -c steam-run ./mybinary"
          echo ""
          echo "  Or wrap a single invocation in an FHS shell:"
          echo "    nix-shell -p steam-run --run 'steam-run ./mybinary'"
          echo ""
          echo "  Libraries already provided: zlib, openssl, curl, gtk3,"
          echo "  wayland, mesa, libGL, alsa-lib, and more."
          echo "  To add more: edit modules/compat/nix-ld.nix"
        }

        # --- Nix dots linting (mirrors CI: statix + deadnix + alejandra) ---
        nlint() {
          local dots="$HOME/code/nix-dots"
          echo "==> statix" \
            && nix run nixpkgs#statix -- check "$dots" \
            && echo "==> deadnix" \
            && nix run nixpkgs#deadnix -- --fail "$dots" \
            && echo "==> alejandra (fmt check)" \
            && nix fmt "$dots" -- --check . \
            && echo "✓ all checks passed"
        }

        # --- Nix package version checks ---
        # nv neovim        → version in your pinned nixpkgs (25.11)
        # nvu neovim       → version in nixpkgs-unstable
        # nvc neovim       → compare both side by side
        nv() {
          nix eval --raw "github:NixOS/nixpkgs/nixos-25.11#''${1}.version" 2>/dev/null \
            && echo || echo "''${1}: not found in nixos-25.11"
        }
        nvu() {
          nix eval --raw "github:NixOS/nixpkgs/nixos-unstable#''${1}.version" 2>/dev/null \
            && echo || echo "''${1}: not found in nixos-unstable"
        }
        nvc() {
          echo "25.11:    $(nix eval --raw "github:NixOS/nixpkgs/nixos-25.11#''${1}.version" 2>/dev/null || echo 'not found')"
          echo "unstable: $(nix eval --raw "github:NixOS/nixpkgs/nixos-unstable#''${1}.version" 2>/dev/null || echo 'not found')"
        }

        # --- System info on shell start ---
        fastfetch
      '';
    };
  };
}
