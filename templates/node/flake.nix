{
  description = "Node.js / TypeScript dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forSystems = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
  in {
    devShells = forSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_24
          corepack
        ];
        shellHook = "echo \"Node $(node --version) | npm $(npm --version)\"";
      };
    });
  };
}
