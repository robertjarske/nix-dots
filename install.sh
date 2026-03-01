#!/usr/bin/env bash
# NixOS install script — run from the NixOS live ISO
# Usage: ./install.sh <hostname>   (bastion or forge)
set -euo pipefail

HOSTNAME="${1:?Usage: $0 <hostname>}"
REPO="github:robertjarske/nix-dots"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Step 1: Keyboard layout ─────────────────────────────────────────────────
echo "» Setting keyboard layout to sv-latin1..."
sudo loadkeys sv-latin1

# ── Step 2: SSH ─────────────────────────────────────────────────────────────
echo ""
echo "» Starting SSH so you can access this machine from a second device."
echo "  You will need it to copy hardware-configuration.nix into the repo."
echo ""
read -rsp "  Set a temporary password for the nixos user: " ssh_pass; echo
echo "nixos:${ssh_pass}" | sudo chpasswd
sudo systemctl start sshd
echo ""
echo "  SSH is up. Connect from your second device with:"
echo "    ssh nixos@$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -1)"

# ── Step 3: LUKS passphrase ─────────────────────────────────────────────────
echo ""
echo "» LUKS fallback passphrase — this becomes keyslot 0 (emergency fallback)."
echo "  Save it in 1Password before continuing."
echo ""
while true; do
  read -rsp "  Enter passphrase: " pass1; echo
  read -rsp "  Confirm passphrase: " pass2; echo
  [[ "$pass1" == "$pass2" ]] && break
  echo "  Passphrases do not match, try again."
done
echo -n "$pass1" > /tmp/luks-password

# ── Step 4: Disko ───────────────────────────────────────────────────────────
echo ""
echo "» Disko will wipe and partition the disk for ${HOSTNAME}."
read -rp "  Type 'yes' to confirm: " confirm
[[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 1; }

sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode disko \
  --flake "${REPO}#${HOSTNAME}"

echo ""
echo "» Disk layout:"
lsblk

# ── Step 5: Hardware configuration ──────────────────────────────────────────
echo ""
echo "» Generating hardware configuration..."
sudo nixos-generate-config --no-filesystems --root /mnt

echo ""
echo "  From your second device, grab the file with:"
echo "    scp nixos@$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -1):/mnt/etc/nixos/hardware-configuration.nix ."
echo ""
echo "  Copy it to hosts/${HOSTNAME}/hardware-configuration.nix in the repo,"
echo "  commit and push."
echo ""

# ── Step 6: Install ─────────────────────────────────────────────────────────
while true; do
  read -rp "  Press Enter once pushed to continue..."
  echo ""
  echo "» Pulling latest changes..."
  git -C "$REPO_DIR" pull --ff-only

  if diff -q \
      "$REPO_DIR/hosts/${HOSTNAME}/hardware-configuration.nix" \
      /mnt/etc/nixos/hardware-configuration.nix > /dev/null 2>&1; then
    break
  fi

  echo ""
  echo "  Files still differ. Diff:"
  diff "$REPO_DIR/hosts/${HOSTNAME}/hardware-configuration.nix" \
       /mnt/etc/nixos/hardware-configuration.nix || true
  echo ""
  echo "  Commit and push the correct file, then press Enter to retry."
done

echo "» Running nixos-install..."
sudo nixos-install --no-root-passwd --flake "${REPO_DIR}#${HOSTNAME}"

# ── Step 7: Cleanup ─────────────────────────────────────────────────────────
rm -f /tmp/luks-password

echo ""
echo "✓ Install complete. Remove the USB drive."
read -rp "» Reboot now? [Y/n] " do_reboot
[[ "${do_reboot,,}" == "n" ]] || sudo reboot
