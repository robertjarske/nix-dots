{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- Modern core utils ---
    eza # modern ls
    bat # modern cat
    fd # modern find
    xcp # modern cp
    moreutils # sponge etc.
    jq # json processing
    unzip # extracting downloads
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

        # --- Work: project dirs ---
        apps = "cd ~/code/applications";
        core = "cd ~/code/core";
        common = "cd ~/code/common";
        socket-server = "cd ~/code/socket-server";
        dots = "cd ~/code/nix-dots";

        # --- SSH shortcuts (kitten ssh preserves kitty terminal protocol over SSH) ---
        s = "kitten ssh";
        buildserver = "s buildserver";
        docker-server = "s docker-server";
        docker-server2 = "s docker-server2";
        docker-server3 = "s docker-server3";
        prod = "s prod";
        gitlab = "s gitlab";

        # --- Snapper / @home snapshots ---
        snaps = "snapper -c home list"; # list all home snapshots

        # --- Nix dev shells ---
        ds = "nix develop"; # enter current project's dev shell
        nsh = "nix shell"; # quick: nix shell nixpkgs#foo

        # --- Nix system management ---
        nrs = "sudo nixos-rebuild switch --flake ~/code/nix-dots#$(hostname)";
        ngen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        ngc = "sudo nix-collect-garbage -d";
        nss = "nix search nixpkgs";

        # --- Config quick-open ---
        zsh_config = "nvim ~/code/nix-dots/home/common/zsh.nix";
        kitty_config = "nvim ~/code/nix-dots/home/common/kitty.nix";
        aa = "nvim ~/code/nix-dots/home/common/zsh.nix";
        reload = "source ~/.zshrc";
        vim_config = "nvim ~/.config/nvim";
      };

      initContent = ''
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
