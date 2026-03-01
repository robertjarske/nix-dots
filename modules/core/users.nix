{ config, lib, pkgs, ... }:
{
  options.host.username = lib.mkOption {
    type = lib.types.str;
    description = "Primary user account name";
  };

  config = {
    users.users.${config.host.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "docker" ];
      shell = pkgs.zsh;
      # Used on first boot before agenix can decrypt (host key not yet in secrets.nix).
      # Change immediately after first login: passwd
      initialPassword = "changeme";
      hashedPasswordFile = config.age.secrets.user-password.path;
    };

    security.sudo.wheelNeedsPassword = true;
    programs.zsh.enable = true;
  };
}
