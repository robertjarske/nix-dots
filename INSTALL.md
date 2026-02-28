# NixOS Fresh Install — bastion

Documented procedure including all lessons learned from the first install.

---

## Prerequisites

- NixOS minimal ISO on a bootable USB
- A second device to push config changes from during install
- WiFi credentials or ethernet
- A strong LUKS fallback passphrase (store in a password manager)

---

## Step 1 — Boot and basic setup

Boot the NixOS ISO. Once at the live shell:

```bash
# Set Swedish keyboard layout
loadkeys sv-latin1

# Connect to WiFi (use nmtui for a guided interface)
nmtui
```

---

## Step 2 — Enable flakes

`sudo` does not inherit exported environment variables, so pass the flag explicitly to every `nix` command rather than using `export`:

```bash
# Do NOT use: export NIX_CONFIG="experimental-features = nix-command flakes"
# Instead, pass it explicitly on each nix command (see Step 3)
```

---

## Step 3 — Set LUKS fallback password

This becomes keyslot 0 — the emergency fallback if both YubiKeys are unavailable. Choose a strong passphrase and store it somewhere safe before running this.

```bash
echo -n "your-strong-passphrase" > /tmp/luks-password
```

---

## Step 4 — Partition, format and mount with disko

Disko reads the partition layout from the flake config and handles everything declaratively. **This is destructive — it wipes the target disk.**

Because flakes are experimental, pass the flag explicitly:

```bash
sudo nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode disko \
  --flake github:robertjarske/nix-dots#bastion
```

Verify everything mounted correctly:

```bash
lsblk
```

Expected output shows `/dev/nvme0n1p1` mounted at `/mnt/boot` and `/dev/nvme0n1p2` as LUKS with all BTRFS subvolumes mounted under `/mnt`.

---

## Step 5 — Generate hardware configuration

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix
```

Copy the output into `hosts/bastion/hardware-configuration.nix` in the repo on your second device, commit and push before continuing.

---

## Step 6 — Run nixos-install

Do **not** run `nixos-install` pointing at GitHub directly — it cannot write the lock file to a remote URL. Clone the repo locally first:

```bash
# /mnt/etc/nixos already exists from nixos-generate-config, use a different path
git clone https://github.com/robertjarske/nix-dots /tmp/nix-dots
cd /tmp/nix-dots
sudo nixos-install --no-root-passwd --flake .#bastion
```

---

## Step 7 — Clean up and reboot

```bash
rm /tmp/luks-password
reboot
```

Remove the USB when the machine powers off.

---

## Step 8 — First boot

At the LUKS prompt enter the passphrase set in Step 3.

Login at the console:
- user: `gast`
- password: `changeme` (set as `initialPassword` in users.nix)

Change it immediately:

```bash
passwd
```

Verify sudo works:

```bash
sudo whoami  # Should return: root
```

---

## Step 9 — Verify rebuild works

Confirm the machine can rebuild itself from the repo:

```bash
cd ~
git clone https://github.com/robertjarske/nix-dots
cd nix-dots
sudo nixos-rebuild switch --flake .#bastion
```

---

## Known gotchas

**Disko partlabel naming** — disko names partitions as `disk-<diskname>-<partname>`. With `disk.main` and partition `luks`, the resulting partlabel is `disk-main-luks`, not `luks`. The boot module must reference `/dev/disk/by-partlabel/disk-main-luks`.

**sudo and NIX_CONFIG** — `export NIX_CONFIG=...` does not survive `sudo`. Always pass `--extra-experimental-features "nix-command flakes"` explicitly on nix commands that need it in the live ISO.

**nixos-install from GitHub** — fails with a lock file write error when pointing at a remote flake URL. Always clone the repo locally and run from there.

**`/mnt/etc/nixos` is not empty** — `nixos-generate-config` writes there, so you cannot clone the repo into that path. Use `/tmp/nix-dots` or similar.

---

## Post-install checklist

- [ ] Password changed with `passwd`
- [ ] `sudo whoami` returns `root`
- [ ] `sudo nixos-rebuild switch --flake .#bastion` succeeds

---

## Step 10 — Enable hibernation (required, not optional)

The swap subvolume and 32 GB swapfile are allocated specifically for hibernation.
Without this step, suspend-to-disk will silently fail or panic.

Get the resume offset for the BTRFS swapfile:

```bash
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Copy the number it prints (e.g. `533760`), then add it to `modules/core/boot.nix`:

```nix
boot.kernelParams = [ "resume_offset=533760" ];
```

Commit, push, and rebuild:

```bash
sudo nixos-rebuild switch --flake .#bastion
```

**This must be done before the machine first suspends, otherwise the resume_offset in boot.nix is wrong (defaulting to none) and the kernel will not know where to find the hibernation image.**

---

## Step 11 — Enable Secure Boot (Lanzaboote)

Lanzaboote is already enabled in the config (`host.secureboot.enable = true`). These steps activate it in the firmware.

**Keys must be created before rebuilding with lanzaboote**, so that the boot files get signed on first activation.

```bash
# 1. Generate Secure Boot keys (stored at /etc/secureboot)
sudo sbctl create-keys

# 2. Rebuild — lanzaboote signs the boot files with the new keys
sudo nixos-rebuild switch --flake .#bastion   # or .#forge

# 3. Verify all boot files are signed (every line should show ✓)
sudo sbctl verify

# 4. Enroll your keys into UEFI firmware
#    --microsoft keeps Microsoft's keys — required on most hardware to avoid
#    breaking firmware updates and option ROMs signed by Microsoft
sudo sbctl enroll-keys --microsoft

# 5. Reboot → enter BIOS → enable Secure Boot → save and exit
reboot

# 6. Verify after reboot
bootctl status   # should show: Secure Boot: enabled
```

---

## Step 12 — Enroll YubiKeys for FIDO2 LUKS unlock

After first boot the disk uses the password-only keyslot. Add both YubiKeys:

```bash
# Enroll YubiKey #1 (plug in first)
sudo systemd-cryptenroll /dev/nvme0n1p2 \
  --fido2-device=auto \
  --fido2-with-client-pin=yes

# Swap to YubiKey #2 and enroll it
sudo systemd-cryptenroll /dev/nvme0n1p2 \
  --fido2-device=auto \
  --fido2-with-client-pin=yes

# Verify keyslots
sudo cryptsetup luksDump /dev/nvme0n1p2
```

At next reboot the LUKS prompt will accept either YubiKey (touch + PIN). The passphrase keyslot remains as a fallback.
