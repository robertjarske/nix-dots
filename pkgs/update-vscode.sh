#!/usr/bin/env bash
# Updates pkgs/vscode-latest.nix to the latest stable VSCode release.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/vscode-latest.nix"

api_response=$(curl -s "https://update.code.visualstudio.com/api/update/linux-x64/stable/latest")
version=$(echo "$api_response" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
current=$(grep 'version = ' "$NIX_FILE" | head -1 | grep -oP '"[^"]+"' | tr -d '"')

if [[ "$version" == "$current" ]]; then
  echo "Already on latest: $version"
  exit 0
fi

echo "Updating $current -> $version"

# Patch in the new version with a dummy hash, then let Nix tell us the real one.
sed -i "s|version = \".*\";|version = \"$version\";|" "$NIX_FILE"
sed -i "s|hash = \".*\";|hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";|" "$NIX_FILE"

sri_hash=$(nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel \
             --no-link 2>&1 \
           | grep "got:" | grep -oP 'sha256-\S+')

sed -i "s|hash = \".*\";|hash = \"$sri_hash\";|" "$NIX_FILE"

echo "Done. Rebuild with: sudo nh os switch"
