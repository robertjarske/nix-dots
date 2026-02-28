{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    teams-for-linux
    beekeeper-studio
    mongodb-compass
    azuredatastudio
    bruno
  ];
}
