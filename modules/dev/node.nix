{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nodejs_24
    corepack
    yarn
    nodePackages.prettier
    nodePackages.eslint
  ];
}
