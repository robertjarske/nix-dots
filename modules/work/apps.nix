{pkgs, ...}: let
  # teams-for-linux reports WM class as "electron" on native Wayland, breaking
  # icon lookup in wayle/hyprpanel. --class sets the X11/Wayland WM class.
  teams-for-linux-fixed = pkgs.symlinkJoin {
    name = "teams-for-linux";
    paths = [pkgs.teams-for-linux];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/teams-for-linux \
        --add-flags "--class=teams-for-linux"
    '';
  };
in {
  environment.systemPackages = with pkgs; [
    teams-for-linux-fixed
    mongodb-compass
    azuredatastudio
    bruno
  ];
}
