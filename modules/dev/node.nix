{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nodejs_24
    corepack
    pnpm
    yarn
  ];
}
