{pkgs, ...}: {
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
  # Disable the GCR SSH agent that gnome-keyring enables by default — we use
  # programs.ssh.startAgent instead (systemd-managed, supports FIDO2 SK keys).
  services.gnome.gcr-ssh-agent.enable = false;

  environment.systemPackages = [pkgs.catppuccin-sddm];
}
