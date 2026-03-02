{
  agenix,
  pkgs,
  ...
}: {
  environment.systemPackages = [agenix.packages.${pkgs.stdenv.hostPlatform.system}.default];
}
