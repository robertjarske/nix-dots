{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    teams-for-linux
    mongodb-compass
    azuredatastudio
    bruno
  ];
}
