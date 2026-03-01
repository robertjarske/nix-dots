{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # --- Modern core utils ---
    eza        # modern ls
    bat        # modern cat
    fd         # modern find
    xcp        # modern cp
    moreutils  # sponge etc.
    jq         # json processing
    unzip      # extracting downloads

    # --- Search / fuzzy ---
    ripgrep    # fast grep (also used by neovim telescope)
    fzf        # fuzzy finder

    # --- System monitoring ---
    btop       # top replacement
    dust       # intuitive du
    ncdu       # ncurses du

    # --- Network utils ---
    nmap       # network scanner
    whois      # domain lookup
    rsync      # file sync

    # --- Misc CLI ---
    bc         # calculator
    navi       # interactive cheatsheet
    lazygit    # git TUI
    lazydocker # docker TUI
  ];

  programs.bat = {
    enable = true;
    config = {
      theme = "Dracula";
      tabs  = "2";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable  = true;
      plugins = [ "git" ]; # provides gwip (used in wip alias)
      # No theme — starship handles the prompt
    };

    history = {
      size       = 10000;
      save       = 10000;
      ignoreDups = true;
      share      = true;
    };

    plugins = [
      {
        name = "zsh-autosuggestions";
        src  = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src  = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];

    sessionVariables = {
      EDITOR = "nvim";
    };

    shellAliases = {
      # --- Core tools ---
      vim  = "nvim";
      ls   = "eza --icons -a --group-directories-first";
      lsa  = "eza -la --git --group-directories-first";
      tree = "eza --icons -a --group-directories-first --tree --level=3";
      cat  = "bat";
      cp   = "xcp";

      # --- Docker ---
      dps  = "docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'";
      dive = "docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive";

      # --- Git quick-fire ---
      asd    = "git add . && git commit -m 'asd' && git push";
      wip    = "gwip && git push";
      fix    = "git add . && git commit -m 'fix' && git push";
      gempty = "git commit --allow-empty --allow-empty-message -m '' && git push";

      # --- Work: project dirs ---
      apps          = "cd ~/code/applications";
      core          = "cd ~/code/core";
      common        = "cd ~/code/common";
      socket-server = "cd ~/code/socket-server";
      dots          = "cd ~/code/nix-dots";

      # --- SSH shortcuts (kitten ssh preserves kitty terminal protocol over SSH) ---
      s              = "kitten ssh";
      buildserver    = "s buildserver";
      docker-server  = "s docker-server";
      docker-server2 = "s docker-server2";
      docker-server3 = "s docker-server3";
      prod           = "s prod";
      gitlab         = "s gitlab";

      # --- Nix dev shells ---
      ds  = "nix develop";  # enter current project's dev shell
      nsh = "nix shell";    # quick: nix shell nixpkgs#foo

      # --- Config quick-open ---
      zsh_config   = "nvim ~/code/nix-dots/home/common/zsh.nix";
      kitty_config = "nvim ~/code/nix-dots/home/common/kitty.nix";
      aa           = "nvim ~/code/nix-dots/home/common/zsh.nix";
      reload       = "source ~/.zshrc";
      vim_config   = "nvim ~/.config/nvim";
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

      # --- System info on shell start ---
      fastfetch
    '';
  };
}
