{
  description = "PHP + Composer dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forSystems = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
  in {
    devShells = forSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          (php84.withExtensions ({all, ...}:
            with all; [
              curl
              mbstring
              pdo
              pdo_mysql
              pdo_pgsql
              redis
              xdebug
              zip
            ]))
          php84Packages.composer
        ];
        shellHook = "echo \"PHP $(php --version | head -1)\"";
      };
    });
  };
}
