# Tracks the latest stable VSCode release, ahead of what nixpkgs-unstable packages.
# Run pkgs/update-vscode.sh to bump to a newer release.
{unstable, ...}: let
  version = "1.111.0";
  hash = "sha256-3s0UzfkufKXXm57JgKaMan/SRAlGTLmdIRXXpzxQvAo=";
in
  unstable.vscode.overrideAttrs (_: {
    inherit version;
    src = unstable.fetchurl {
      name = "VSCode_${version}_linux-x64.tar.gz";
      url = "https://update.code.visualstudio.com/${version}/linux-x64/stable";
      inherit hash;
    };
  })
