{ ... }:
{
  imports = [
    ./common/zsh.nix
    ./common/kitty.nix
    ./common/starship.nix
    ./common/git.nix
    ./common/neovim.nix
    ./common/gtk.nix
    ./common/hyprland.nix
    ./common/rofi.nix
    ./common/matugen.nix
    ./common/hyprpanel.nix
    ./common/work-certs.nix
    ./common/fastfetch.nix
    ./common/ssh.nix
    ./common/vscode.nix
    ./common/mpv.nix
    ./common/direnv.nix
  ];

  home.stateVersion = "25.11";
}