{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;

    # mutableExtensionsDir = true allows VSCode to install extensions via the
    # marketplace UI in addition to the ones listed below. Set to false if you
    # want nix to be the sole source of truth (removes marketplace-installed extensions).
    mutableExtensionsDir = true;

    extensions = with pkgs.vscode-extensions; [
      # --- Nix ---
      jnoortheen.nix-ide

      # --- Web / Frontend ---
      bradlc.vscode-tailwindcss
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      vue.volar
      ms-vscode.vscode-typescript-next

      # --- PHP ---
      bmewburn.vscode-intelephense-client

      # --- Python ---
      ms-python.python
      ms-python.debugpy
      ms-python.vscode-pylance

      # --- Go ---
      golang.go

      # --- YAML / TOML / Data ---
      redhat.vscode-yaml
      tamasfe.even-better-toml

      # --- DX / Code quality ---
      eamodio.gitlens
      usernamehw.errorlens
      yoavbls.pretty-ts-errors

      # --- Theme / Icons ---
      catppuccin.catppuccin-vsc
      pkief.material-icon-theme
    ];

    # Extensions not yet in nixpkgs — install manually via the marketplace:
    #   adpyke.codesnap
    #   beardedbear.beardedicons
    #   christian-kohler.path-intellisense
    #   dalirnet.doctypes
    #   docker.docker
    #   dsznajder.es7-react-js-snippets
    #   file-icons.file-icons
    #   formulahendry.auto-rename-tag
    #   getpsalm.psalm-vscode-plugin
    #   github.copilot          (proprietary, Microsoft marketplace only)
    #   github.copilot-chat     (proprietary, Microsoft marketplace only)
    #   gruntfuggly.todo-tree
    #   humao.rest-client
    #   inferrinizzard.prettier-sql-vscode
    #   jock.svg
    #   kasik96.latte
    #   lokalise.i18n-ally
    #   matthewpi.caddyfile-support
    #   mblode.twig-language-2
    #   mechatroner.rainbow-csv
    #   motion.motion-vscode-extension
    #   ms-azuretools.vscode-containers
    #   ms-playwright.playwright
    #   naumovs.color-highlight
    #   quicktype.quicktype
    #   redhat.ansible
    #   rvest.vs-code-prettier-eslint
    #   sanderronde.phpstan-vscode
    #   stylelint.vscode-stylelint
    #   tal7aouy.icons
    #   techer.open-in-browser
    #   thearc.tolgee
    #   tyriar.sort-lines
    #   vitest.explorer
    #   wayou.vscode-todo-highlight
    #   wix.vscode-import-cost
    #   wongjn.php-sniffer
    #   xabikos.javascriptsnippets
    #   yzhang.markdown-all-in-one
  };
}
