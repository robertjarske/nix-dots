{ agenix, config, pkgs, ... }:
{
  environment.systemPackages = [ agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  age.secrets.user-password = {
    file = ../../secrets/user-password.age;
    owner = config.host.username;
  };
}
