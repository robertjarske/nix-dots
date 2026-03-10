{
  pkgs,
  lib,
  config,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  home.packages = [pkgs.fastfetch pkgs.librsvg];

  # Converts ~/Pictures/fastfetch.svg → ~/Pictures/fastfetch-logo.png at activation.
  # fastfetch's kitty protocol requires a raster image — SVG is not supported by its
  # internal decoder (stb_image). rsvg-convert produces a high-quality PNG from the SVG.
  # Skipped if the SVG hasn't changed since the last run.
  home.activation.fastfetchConvertLogo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    svg="${homeDir}/Pictures/fastfetch.svg"
    png="${homeDir}/Pictures/fastfetch-logo.png"
    if [ -f "$svg" ]; then
      if [ ! -f "$png" ] || [ "$svg" -nt "$png" ]; then
        ${pkgs.librsvg}/bin/rsvg-convert "$svg" -o "$png"
      fi
    fi
  '';

  # Config is written to ~/.config/fastfetch/config.jsonc.
  # fastfetch is called at shell start from zsh.nix's initContent.
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "~/Pictures/fastfetch-logo.png",
        "type": "kitty",
        "height": 15,
        "width": 48,
      },
      "display": {
        "separator": " ➜ ",
      },
      "modules": [
        "break",
        "break",
        { "type": "custom",      "format": "\u001b[35m╭─── os ────────────────────────────────────────────────────────╮\u001b[0m" },
        { "type": "os",           "key": "  ",       "keyColor": "35" },
        { "type": "kernel",       "key": "  ",   "keyColor": "35" },
        { "type": "uptime",       "key": "  ",   "keyColor": "35" },
        { "type": "packages",     "key": " 󰏖 ",     "keyColor": "35" },
        { "type": "shell",        "key": "  ",    "keyColor": "35" },
        { "type": "datetime",     "key": "  ", "keyColor": "35" },
        { "type": "custom",      "format": "\u001b[35m╰───────────────────────────────────────────────────────────────╯\u001b[0m" },
        "break",
        { "type": "custom",      "format": "\u001b[32m╭─── desktop ───────────────────────────────────────────────────╮\u001b[0m" },
        { "type": "wm",           "key": "  ",        "keyColor": "32" },
        { "type": "wmtheme",      "key": " 󰉼 ",  "keyColor": "32" },
        { "type": "icons",        "key": " 󰀻 ",    "keyColor": "32" },
        { "type": "terminal",     "key": "  ", "keyColor": "32" },
        { "type": "terminalfont", "key": "  ",     "keyColor": "32" },
        { "type": "custom",      "format": "\u001b[32m╰───────────────────────────────────────────────────────────────╯\u001b[0m" },
        "break",
        { "type": "custom",      "format": "\u001b[33m╭─── hardware ──────────────────────────────────────────────────╮\u001b[0m" },
        { "type": "host",         "key": "  ",     "keyColor": "33", "format": "{5} {1} Type {2}" },
        { "type": "cpu",          "key": "  ",      "keyColor": "33", "format": "{1} ({3}) @ {7} GHz" },
        { "type": "gpu",          "key": " 󰢮 ",      "keyColor": "33" },
        { "type": "vulkan",       "key": "  ",   "keyColor": "33" },
        { "type": "opengl",       "key": "  ",   "keyColor": "33" },
        { "type": "memory",       "key": "  ",      "keyColor": "33" },
        { "type": "btrfs",        "key": "  ",    "keyColor": "33" },
        { "type": "command", "key": " ├  ", "keyColor": "33", "text": "btrfs filesystem df / 2>/dev/null | awk '/^Data/{gsub(/[,=:]/,\" \"); printf \"data: %s / %s (%s)\", $6, $4, tolower($2)}'" },
        { "type": "command", "key": " └  ", "keyColor": "33", "text": "btrfs filesystem df / 2>/dev/null | awk '/^Metadata/{gsub(/[,=:]/,\" \"); printf \"meta: %s / %s (%s)\", $6, $4, tolower($2)}'" },
        { "type": "battery",      "key": "  ",  "keyColor": "33" },
        { "type": "custom",      "format": "\u001b[33m╰───────────────────────────────────────────────────────────────╯\u001b[0m" },
        "break",
        { "type": "custom",      "format": "\u001b[34m╭─── network ───────────────────────────────────────────────────╮\u001b[0m" },
        { "type": "localip",  "key": "  ",      "keyColor": "34", "defaultRouteOnly": true, "showIpv6": false },
        { "type": "custom",      "format": "\u001b[34m╰───────────────────────────────────────────────────────────────╯\u001b[0m" },
        "break",
        { "type": "colors", "paddingLeft": 2, "symbol": "circle" },
        "break",
      ],
    }
  '';
}
