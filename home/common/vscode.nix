{ pkgs, config, vscodeExtensions, ... }:
let
  mkt = vscodeExtensions.vscode-marketplace;
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    profiles.default.extensions = [
      # --- Nix ---
      mkt.jnoortheen.nix-ide
      mkt.arrterian.nix-env-selector
      mkt.mkhl.direnv

      # --- Web / Frontend ---
      mkt.bradlc.vscode-tailwindcss
      mkt.dbaeumer.vscode-eslint
      mkt.esbenp.prettier-vscode
      mkt.vue.volar
      mkt.ms-vscode.vscode-typescript-next
      mkt.dsznajder.es7-react-js-snippets
      mkt.wix.vscode-import-cost
      mkt.wix.glean
      mkt.iulian-radu-at.find-unused-exports
      mkt.huuums.vscode-fast-folder-structure
      mkt.syler.sass-indented
      mkt.stylelint.vscode-stylelint
      mkt.jock.svg
      mkt.mblode.twig-language
      mkt.kisstkondoros.vscode-gutter-preview

      # --- PHP ---
      mkt.bmewburn.vscode-intelephense-client
      mkt.wongjn.php-sniffer
      mkt.ikappas.phpcs

      # --- Python ---
      mkt.ms-python.python
      mkt.ms-python.debugpy
      mkt.ms-python.vscode-pylance
      mkt.ms-python.black-formatter
      mkt.donjayamanne.python-environment-manager

      # --- Go ---
      mkt.golang.go

      # --- Rust ---
      mkt.rust-lang.rust-analyzer
      mkt.dustypomerleau.rust-syntax

      # --- YAML / TOML / XML / Data ---
      mkt.redhat.vscode-yaml
      mkt.tamasfe.even-better-toml
      mkt.redhat.vscode-xml
      mkt.pflannery.vscode-versionlens
      mkt.arcanis.vscode-zipfs

      # --- Docker ---
      mkt.ms-azuretools.vscode-docker

      # --- DX / Code quality ---
      mkt.eamodio.gitlens
      mkt.usernamehw.errorlens
      mkt.yoavbls.pretty-ts-errors
      mkt.aaron-bond.better-comments
      mkt.christian-kohler.path-intellisense
      mkt.dalirnet.doctypes
      mkt.wayou.vscode-todo-highlight
      mkt.ybaumes.highlight-trailing-white-spaces

      # --- Theme / Icons ---
      mkt.catppuccin.catppuccin-vsc
      mkt.catppuccin.catppuccin-vsc-icons
      mkt.pkief.material-icon-theme
      mkt.zhuangtongfa.material-theme

      # github.copilot and github.copilot-chat are proprietary —
      # install manually via the marketplace.
    ];

    profiles.default.keybindings = [
      {
        key     = "ctrl+shift+down";
        command = "editor.action.copyLinesDownAction";
        when    = "editorTextFocus && !editorReadonly";
      }
      {
        key     = "ctrl+shift+alt+down";
        command = "-editor.action.copyLinesDownAction";
        when    = "editorTextFocus && !editorReadonly";
      }
      {
        key     = "ctrl+shift+up";
        command = "editor.action.copyLinesUpAction";
        when    = "editorTextFocus && !editorReadonly";
      }
      {
        key     = "ctrl+shift+alt+up";
        command = "-editor.action.copyLinesUpAction";
        when    = "editorTextFocus && !editorReadonly";
      }
      {
        key     = "ctrl+shift+enter";
        command = "editor.emmet.action.wrapWithAbbreviation";
      }
      {
        key     = "ctrl+f";
        command = "-list.find";
        when    = "listFocus && listSupportsFind";
      }
      {
        key     = "ctrl+shift+7";
        command = "editor.action.commentLine";
        when    = "editorTextFocus && !editorReadonly";
      }
      {
        key     = "ctrl+/";
        command = "-editor.action.commentLine";
        when    = "editorTextFocus && !editorReadonly";
      }
    ];

    profiles.default.userSettings = {
      "workbench.colorTheme"                      = "Catppuccin Macchiato";
      "workbench.iconTheme"                       = "material-icon-theme";
      "workbench.secondarySideBar.defaultVisibility" = "hidden";

      "security.workspace.trust.untrustedFiles"   = "open";
      "open-in-browser.default"                   = "chrome";

      "editor.fontFamily"                         = "'Fira Code'";
      "editor.fontLigatures"                      = true;
      "editor.tabCompletion"                      = "on";
      "editor.stickyScroll.enabled"               = true;
      "editor.cursorStyle"                        = "line-thin";
      "editor.inlineSuggest.suppressSuggestions"  = true;
      "editor.quickSuggestions"                   = { "strings" = "on"; };

      "files.autoSave"                            = "onWindowChange";
      "files.trimTrailingWhitespace"              = true;

      "doctypes.descriptionWrap"                  = 115;

      # phpSniffer uses composer-installed binaries in the user's local dir
      "phpSniffer.executablesFolder" = "${config.home.homeDirectory}/.config/composer/vendor/bin";

      "css.validate"                              = false;
      "less.validate"                             = false;
      "scss.validate"                             = false;
      "stylelint.snippet"                         = [ "css" "less" "postcss" "scss" ];
      "stylelint.validate"                        = [ "css" "less" "postcss" "scss" ];

      "emmet.includeLanguages" = {
        "html"            = "true";
        "javascript"      = "true";
        "javascriptreact" = "true";
        "twig"            = "html";
      };

      "makefile.configureOnOpen"                  = false;
      "redhat.telemetry.enabled"                  = false;
      "gitlens.codeLens.enabled"                  = false;
      "gitlens.ai.model"                          = "vscode";
      "gitlens.ai.vscode.model"                   = "copilot:gpt-4.1";

      "material-icon-theme.files.associations"    = { "*.neon" = "phpstan"; };

      "nightwatch.quickSettings.parallels"        = 22;
      "nightwatch.quickSettings.environments"     = "chrome";
      "nightwatch.quickSettings.headlessMode"     = false;
      "nightwatch.quickSettings.openReport"       = false;

      "playwright.reuseBrowser"                   = false;
      "playwright.showTrace"                      = true;

      "docker.extension.enableComposeLanguageServer" = false;

      "json.schemaDownload.trustedDomains" = {
        "https://schemastore.azurewebsites.net/" = true;
        "https://raw.githubusercontent.com/"     = true;
        "https://www.schemastore.org/"           = true;
        "https://json.schemastore.org/"          = true;
        "https://json-schema.org/"               = true;
        "https://ui.shadcn.com/schema.json"      = true;
        "https://turbo.build"                    = true;
        "https://docs.renovatebot.com"           = true;
      };

      "[javascript]" = {
        "editor.maxTokenizationLineLength" = 2500;
        "editor.tabSize"                   = 2;
        "editor.formatOnSave"              = true;
        "editor.defaultFormatter"          = "esbenp.prettier-vscode";
      };
      "[typescript]" = {
        "editor.maxTokenizationLineLength" = 2500;
        "editor.tabSize"                   = 2;
        "editor.formatOnSave"              = true;
        "editor.defaultFormatter"          = "esbenp.prettier-vscode";
      };
      "[javascriptreact]" = {
        "editor.tabSize"          = 2;
        "editor.formatOnSave"     = true;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescriptreact]" = {
        "editor.tabSize"          = 2;
        "editor.formatOnSave"     = true;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[json]" = {
        "editor.formatOnSave"              = true;
        "editor.quickSuggestions"          = { "strings" = true; };
        "editor.suggest.insertMode"        = "replace";
        "editor.defaultFormatter"          = "esbenp.prettier-vscode";
      };
      "[jsonc]" = {
        "editor.formatOnSave"              = true;
        "editor.quickSuggestions"          = { "strings" = true; };
        "editor.suggest.insertMode"        = "replace";
        "editor.defaultFormatter"          = "esbenp.prettier-vscode";
      };
      "[php]" = {
        "editor.linkedEditing" = true;
        "editor.tabSize"       = 4;
      };
      "[css]" = {
        "editor.formatOnSave"      = true;
        "editor.tabSize"           = 2;
        "editor.defaultFormatter"  = "stylelint.vscode-stylelint";
        "editor.codeActionsOnSave" = { "source.fixAll.stylelint" = "explicit"; };
      };
      "[scss]" = {
        "editor.formatOnSave"      = true;
        "editor.tabSize"           = 2;
        "editor.codeActionsOnSave" = { "source.fixAll.stylelint" = "explicit"; };
      };
      "[yaml]"                    = { "editor.defaultFormatter" = "redhat.vscode-yaml"; };
      "[github-actions-workflow]" = { "editor.defaultFormatter" = "redhat.vscode-yaml"; };
      "[dockercompose]" = {
        "editor.insertSpaces"      = true;
        "editor.tabSize"           = 2;
        "editor.autoIndent"        = "advanced";
        "editor.quickSuggestions"  = { "other" = true; "comments" = false; "strings" = true; };
        "editor.defaultFormatter"  = "redhat.vscode-yaml";
      };
    };
  };
}
