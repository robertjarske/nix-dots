{pkgs, ...}: {
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment.systemPackages = with pkgs; [
    google-chrome
    vivaldi
    spotify
    nautilus
    udiskie
    openssl
  ];
}
