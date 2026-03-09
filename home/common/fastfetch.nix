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
  #
  # Logo: place your image at ~/Pictures/fastfetch-logo.png (or any path below).
  # The "kitty" type uses kitty's image protocol — only works inside kitty terminal.
  # xdg.configFile."fastfetch/config.jsonc".text = ''
  #   {
  #     "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  #     "display": {
  #       "separator": " ➜  "
  #     },
  #     "modules": [
  #       "break",
  #       "break",
  #       "break",
  #       { "type": "os",       "key": "OS   ", "keyColor": "31" },
  #       { "type": "kernel",   "key": " ├  ", "keyColor": "31" },
  #       { "type": "packages", "key": " ├ 󰏖 ", "keyColor": "31" },
  #       { "type": "shell",    "key": " └  ", "keyColor": "31" },
  #       "break",
  #       { "type": "wm",          "key": "WM   ", "keyColor": "32" },
  #       { "type": "wmtheme",     "key": " ├ 󰉼 ", "keyColor": "32" },
  #       { "type": "icons",       "key": " ├ 󰀻 ", "keyColor": "32" },
  #       { "type": "cursor",      "key": " ├  ", "keyColor": "32" },
  #       { "type": "terminal",    "key": " ├  ", "keyColor": "32" },
  #       { "type": "terminalfont","key": " └  ", "keyColor": "32" },
  #       "break",
  #       {
  #         "type": "host",
  #         "format": "{5} {1} Type {2}",
  #         "key": "PC   ",
  #         "keyColor": "33"
  #       },
  #       {
  #         "type": "cpu",
  #         "format": "{1} ({3}) @ {7} GHz",
  #         "key": " ├  ",
  #         "keyColor": "33"
  #       },
  #       {
  #         "type": "gpu",
  #         "format": "{1} {2} @ {12} GHz",
  #         "key": " ├ 󰢮 ",
  #         "keyColor": "33"
  #       },
  #       { "type": "memory", "key": " ├  ", "keyColor": "33" },
  #       { "type": "swap",   "key": " ├ 󰓡 ", "keyColor": "33" },
  #       { "type": "disk",   "key": " ├ 󰋊 ", "keyColor": "33" },
  #       { "type": "monitor","key": " └  ", "keyColor": "33" },
  #       "break",
  #       "break"
  #     ]
  #   }
  # '';

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "~/Pictures/fastfetch-logo.png",
        "type": "kitty",
        "height": 20,
        "width": 60
      },
      "display": {
        "separator": " ➜  ",
      },
      "modules": [
        "break",
        "break",
        "break",
        {
          "type": "os",
          "key": "OS   ",
          "keyColor": "31", // = color1
        },
        {
          "type": "kernel",
          "key": " ├  ",
          "keyColor": "31",
        },
        {
          "type": "packages",
          "format": "{}",
          "key": " ├ 󰏖 ",
          "keyColor": "31",
        },
        {
          "type": "shell",
          "key": " └  ",
          "keyColor": "31",
        },
        "break",
        {
          "type": "wm",
          "key": "WM   ",
          "keyColor": "32",
        },
        {
          "type": "wmtheme",
          "key": " ├ 󰉼 ",
          "keyColor": "32",
        },
        {
          "type": "icons",
          "key": " ├ 󰀻 ",
          "keyColor": "32",
        },
        {
          "type": "cursor",
          "key": " ├  ",
          "keyColor": "32",
        },
        {
          "type": "terminal",
          "key": " ├  ",
          "keyColor": "32",
        },
        {
          "type": "terminalfont",
          "key": " └  ",
          "keyColor": "32",
        },
        "break",
        {
          "type": "host",
          "format": "{5} {1} Type {2}",
          "key": "PC   ",
          "keyColor": "33",
        },
        {
          "type": "cpu",
          "format": "{1} ({3}) @ {7} GHz",
          "key": " ├  ",
          "keyColor": "33",
        },
        {
          "type": "gpu",
          "format": "{1} {2} @ {12} GHz",
          "key": " ├ 󰢮 ",
          "keyColor": "33",
        },
        {
          "type": "memory",
          "key": " ├  ",
          "keyColor": "33",
        },
        {
          "type": "swap",
          "key": " ├ 󰓡 ",
          "keyColor": "33",
        },
        {
          "type": "disk",
          "key": " ├ 󰋊 ",
          "keyColor": "33",
        },
        {
          "type": "monitor",
          "key": " └  ",
          "keyColor": "33",
        },
        "break",
        "break",
      ],
    }
  '';
}
