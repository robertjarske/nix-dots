#!/usr/bin/env bash
# NixOS install script — run from the NixOS live ISO
# Usage: ./install.sh <hostname>   (bastion or forge)
set -euo pipefail

HOSTNAME="${1:?Usage: $0 <hostname>}"
REPO="github:robertjarske/nix-dots"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Colors ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

step()  { echo -e "\n${BOLD}${CYAN}»${RESET} ${BOLD}$*${RESET}"; }
info()  { echo -e "  ${DIM}$*${RESET}"; }
cmd()   { echo -e "  ${YELLOW}$*${RESET}"; }
warn()  { echo -e "  ${YELLOW}⚠ $*${RESET}"; }
ok()    { echo -e "${GREEN}✓${RESET} $*"; }
err()   { echo -e "  ${RED}✗ $*${RESET}"; }

# ── Step 1: Keyboard layout ──────────────────────────────────────────────────
step "Setting keyboard layout to sv-latin1..."
sudo loadkeys sv-latin1

# ── Step 2: SSH ──────────────────────────────────────────────────────────────
step "Starting SSH so you can access this machine from a second device."
info "You will need it to copy hardware-configuration.nix into the repo."
echo ""
read -rsp "  Set a temporary password for the nixos user: " ssh_pass; echo
echo "nixos:${ssh_pass}" | sudo chpasswd
sudo systemctl start sshd
echo ""
info "SSH is up. Connect from your second device with:"
cmd "ssh nixos@$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -1)"

# ── Step 3: LUKS passphrase ──────────────────────────────────────────────────
step "LUKS fallback passphrase — this becomes keyslot 0 (emergency fallback)."
warn "Save it in 1Password before continuing."
echo ""
while true; do
  read -rsp "  Enter passphrase: " pass1; echo
  read -rsp "  Confirm passphrase: " pass2; echo
  [[ "$pass1" == "$pass2" ]] && break
  err "Passphrases do not match, try again."
done
echo -n "$pass1" > /tmp/luks-password

# ── Step 4: Disko ────────────────────────────────────────────────────────────
step "Disko will wipe and partition the disk for ${BOLD}${HOSTNAME}${RESET}."
read -rp "  Type 'yes' to confirm: " confirm
[[ "$confirm" == "yes" ]] || { err "Aborted."; exit 1; }

sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode disko \
  --flake "${REPO}#${HOSTNAME}"

echo ""
info "Disk layout:"
lsblk

# ── Step 5: Hardware configuration ──────────────────────────────────────────
step "Generating hardware configuration..."
sudo nixos-generate-config --no-filesystems --root /mnt

echo ""
info "From your second device, grab the file with:"
cmd "scp nixos@$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -1):/mnt/etc/nixos/hardware-configuration.nix ."
echo ""
info "Copy it to ${BOLD}hosts/${HOSTNAME}/hardware-configuration.nix${RESET} in the repo."
warn "Do NOT push yet — the next step will give you the full commit instructions."

# ── Step 6: SSH host key (agenix bootstrap) ──────────────────────────────────
# Pre-generate the host key so agenix can decrypt secrets during nixos-install.
# NixOS sshd skips key generation if the file already exists, so this is safe.
step "Pre-generating SSH host key for agenix bootstrap..."
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
sudo chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub
HOST_PUBKEY="$(sudo cat /mnt/etc/ssh/ssh_host_ed25519_key.pub | awk '{print $1, $2}')"

echo ""
info "New ${BOLD}${HOSTNAME}${RESET} host public key:"
echo -e "  ${GREEN}${HOST_PUBKEY}${RESET}"
echo ""
info "On your second device, do the following and then push a single commit:"
echo -e "  ${BOLD}1.${RESET} In ${BOLD}secrets/secrets.nix${RESET}, replace the commented-out ${HOSTNAME} line:"
cmd "   ${HOSTNAME} = \"${HOST_PUBKEY}\";"
info "   and uncomment all  ${BOLD}++ [ ${HOSTNAME} ]${RESET}  entries for its secrets."
echo -e "  ${BOLD}2.${RESET} Run:"
cmd "   nix run .#rekey"
echo -e "  ${BOLD}3.${RESET} Commit and push:"
cmd "   git add -p && git commit -m 'feat(secrets): add ${HOSTNAME} host key + rekey' && git push"

# ── Step 7: Secure boot keys (lanzaboote bootstrap) ─────────────────────────
# sbctl keys must exist before nixos-install so lanzaboote can install the bootloader.
# Keys are created on the live ISO and copied into the target filesystem.
step "Creating secure boot keys..."
sudo nix --extra-experimental-features "nix-command flakes" \
  shell nixpkgs#sbctl --command sbctl create-keys
sudo mkdir -p /mnt/var/lib/sbctl
sudo cp -a /var/lib/sbctl/. /mnt/var/lib/sbctl/
info "Secure boot keys created. Enroll them after first boot with:"
cmd "  sudo sbctl enroll-keys --microsoft"

# ── Step 8: Install ──────────────────────────────────────────────────────────
echo ""
while true; do
  read -rp "  Press Enter once pushed to continue..."
  echo ""
  step "Pulling latest changes..."
  git -C "$REPO_DIR" pull --ff-only

  if diff -q \
      "$REPO_DIR/hosts/${HOSTNAME}/hardware-configuration.nix" \
      /mnt/etc/nixos/hardware-configuration.nix > /dev/null 2>&1; then
    break
  fi

  echo ""
  err "Files still differ. Diff:"
  diff "$REPO_DIR/hosts/${HOSTNAME}/hardware-configuration.nix" \
       /mnt/etc/nixos/hardware-configuration.nix || true
  echo ""
  warn "Commit and push the correct files, then press Enter to retry."
done

step "Running nixos-install..."
sudo nixos-install --no-root-passwd --flake "${REPO_DIR}#${HOSTNAME}"

# ── Step 9: Cleanup ──────────────────────────────────────────────────────────
rm -f /tmp/luks-password

echo ""
ok "Install complete. Remove the USB drive."
read -rp "» Reboot now? [Y/n] " do_reboot
[[ "${do_reboot,,}" == "n" ]] || sudo reboot
