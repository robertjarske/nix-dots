{
  config,
  lib,
  pkgs,
  ...
}: {
  options.host.username = lib.mkOption {
    type = lib.types.str;
    description = "Primary user account name";
  };

  config = {
    users.users.${config.host.username} = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker"];
      shell = pkgs.zsh;
      # Set a real password with `passwd` after first login.
      # mutableUsers = true (NixOS default) persists it across rebuilds.
      initialPassword = "changeme";
    };

    security.sudo.wheelNeedsPassword = true;
    programs.zsh.enable = true;
  };
}
