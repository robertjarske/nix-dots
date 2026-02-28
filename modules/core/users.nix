{ config, lib, pkgs, ... }:
{
  options.host.username = lib.mkOption {
    type = lib.types.str;
    description = "Primary user account name";
  };

  config = {
    users.users.${config.host.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      hashedPasswordFile = config.age.secrets.user-password.path;
    };

    security.sudo.wheelNeedsPassword = true;
    programs.zsh.enable = true;
  };
}
