{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "${pkgs.catppuccin-sddm}/share/sddm/themes/catppuccin-mocha-mauve";
  };

  # Keyring daemon — provides the Secret Service API used by 1Password, Firefox,
  # and other apps to store credentials. PAM integration auto-unlocks it at SDDM
  # login so apps never hit a "unable to save token" error.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    kdePackages.sddm
    catppuccin-sddm
  ];
}
