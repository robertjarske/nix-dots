{ agenix, config, ... }:
{
  environment.systemPackages = [ agenix.packages.x86_64-linux.default ];

  age.secrets.user-password = {
    file = ../../secrets/user-password.age;
    owner = config.host.username;
  };
}
