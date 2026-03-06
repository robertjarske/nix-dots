{pkgs, ...}: {
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment.systemPackages = with pkgs; [
    # --password-store=gnome-libsecret: tells Chromium-based browsers to use the
    # GNOME libsecret backend. Required on Hyprland because XDG_CURRENT_DESKTOP=Hyprland
    # is not recognised as GNOME by Electron's keyring auto-detection.
    (google-chrome.override {commandLineArgs = "--password-store=gnome-libsecret";})
    (vivaldi.override {commandLineArgs = "--password-store=gnome-libsecret";})
    spotify
    nautilus
    udiskie
    openssl
  ];
}
