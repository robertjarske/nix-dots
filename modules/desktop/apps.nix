{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    google-chrome
    vivaldi
    spotify
    nautilus
  ];
}
