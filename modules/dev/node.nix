{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nodejs_24
    (corepack.override {nodejs = nodejs_24;})
    yarn
  ];
}
