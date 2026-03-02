# NixOS Fresh Install

---

## Prerequisites

- NixOS minimal ISO on a bootable USB
- A second device to push config changes from during install
- WiFi credentials or ethernet
- A strong LUKS fallback passphrase (store in 1Password before starting)

---

## Steps 1–8 — Automated

Clone the repo from the live ISO and run the install script:

```bash
git clone https://github.com/robertjarske/nix-dots /tmp/setup
/tmp/setup/install.sh <hostname>   # bastion or forge
```

The script handles:
1. Swedish keyboard layout
2. SSH — starts sshd and prints the IP so you can `scp` from a second device
3. LUKS fallback passphrase (prompted, store it in 1Password)
4. Disko — partitions and formats the disk (destructive, confirms before running)
5. Hardware configuration — generates it and pauses for you to commit it to the repo
6. SSH host key — pre-generates the host key, shows it, and pauses so you can add it to `secrets/secrets.nix`, rekey, and push **from your second device** before the install continues
7. Secure Boot keys — creates sbctl keys and copies them to the target system
8. `nixos-install` — pulls latest changes, verifies hardware config, installs
9. Cleanup and reboot

**Hardware config step:** the script pauses and prints an `scp` command. On your second device:

```bash
scp nixos@<ip>:/mnt/etc/nixos/hardware-configuration.nix .
# copy to hosts/<hostname>/hardware-configuration.nix, commit, push
```

**Rekey step:** the script pauses again after generating the host key and prints exact instructions. On your second device: add the key to `secrets/secrets.nix`, run `nix run .#rekey`, commit and push. Then press Enter in the script.

---

## Step 9 — First boot

At the LUKS prompt enter the passphrase from Step 3.

Login at the console:
- user: `gast` (bastion) or `serobja` (forge)
- password: `changeme` (temporary `initialPassword` — active until agenix decrypts)

Change it immediately:

```bash
passwd
```

> **Note:** The real password is stored in `user-password.age`. Once you complete the
> post-install steps (host key was added to secrets during install → rebuild), agenix
> takes over and `hashedPasswordFile` supersedes `initialPassword`.

---

## Step 10 — Rebuild

```bash
cd ~
git clone https://github.com/robertjarske/nix-dots ~/code/nix-dots
cd ~/code/nix-dots
sudo nixos-rebuild switch --flake .#<hostname>
```

Secrets were already rekeyed during install (step 6), so this should succeed on the first try.

---

## Step 11 — Enable hibernation

Get the resume offset for the BTRFS swapfile:

```bash
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Set it in `hosts/<hostname>/default.nix`:

```nix
host.hibernation.resumeOffset = <number>;
```

Commit, push, and rebuild. **Must be done before the machine first suspends.**

---

## Step 12 — Enable Secure Boot (Lanzaboote)

Secure Boot keys were created during install (step 7) and are already at `/var/lib/sbctl`.
The first rebuild (step 10) signed the boot files. Start from Part B.

### Part A — Verify signing

```bash
# All NixOS boot files should be signed
sudo sbctl verify
```

### Part B — Prepare firmware (Dell-specific, similar on other vendors)

1. Reboot into BIOS → Secure Boot settings
2. Enable **Custom key management**
3. Select **PK** → **Delete** (enters Setup Mode)
4. **Leave Custom key management enabled** — disabling it causes the firmware to reload its factory keys
5. Save and exit → boot into NixOS

### Part C — Enroll keys

```bash
# Confirm Setup Mode before enrolling
sudo sbctl status   # Setup Mode should show ✓ Enabled

# If EFI variables are immutable:
nix shell nixpkgs#e2fsprogs
sudo chattr -i /sys/firmware/efi/efivars/KEK-8be4df61-93ca-11d2-aa0d-00e098032b8c
sudo chattr -i /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f
exit

sudo sbctl enroll-keys --microsoft

# Confirm — Vendor Keys should show: microsoft (not builtin-PK)
sudo sbctl status
```

**If `builtin-PK` still shows:** the firmware reloaded its factory keys. Go back to Part B and keep Custom key management enabled.

### Part D — Enable Secure Boot

1. Reboot into BIOS → enable Secure Boot (Deployed mode) → save
2. Verify:

```bash
sudo sbctl status    # Secure Boot: ✓ Enabled
bootctl status       # Secure Boot: enabled (deployed)
```

---

## Step 13 — Enroll YubiKeys for FIDO2 LUKS unlock

```bash
# Enroll YubiKey #1 (plug in first)
sudo systemd-cryptenroll /dev/nvme0n1p2 \
  --fido2-device=auto \
  --fido2-with-client-pin=yes

# Swap to YubiKey #2 and repeat
sudo systemd-cryptenroll /dev/nvme0n1p2 \
  --fido2-device=auto \
  --fido2-with-client-pin=yes

# Verify keyslots
sudo cryptsetup luksDump /dev/nvme0n1p2
```

At next reboot the LUKS prompt accepts either YubiKey (touch + PIN). The passphrase keyslot remains as fallback.
