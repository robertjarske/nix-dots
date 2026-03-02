{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/sddm.nix
    ../../modules/desktop/audio.nix
    ../../modules/desktop/bluetooth.nix
    ../../modules/desktop/power.nix
    ../../modules/desktop/theme.nix
    ../../modules/desktop/apps.nix
  ];

  host.hibernation.resumeOffset = 533760;
  host.secureboot.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    gh
    psmisc
    _1password-cli
    _1password-gui
    firefox
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["gast"];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "25.11";
}
