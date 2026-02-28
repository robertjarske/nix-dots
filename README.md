# nix-dots

My personal NixOS configuration. Not a framework, not a template — just my machines.

## ⚠️ Personal use only

This repository is **public for reference**, not for collaboration.

- **Do not open issues** — I will not respond to them
- **Do not open pull requests** — they will be closed without review
- **Do not expect support** — nothing here is designed to work for anyone but me

If you find something useful while browsing, great. But this config is tightly coupled to my specific hardware, secrets infrastructure, and workflow. It will not work out of the box for you.

## Stack

| | |
|---|---|
| OS | NixOS 25.11 |
| WM | Hyprland (Wayland) |
| Secrets | [agenix](https://github.com/ryantm/agenix) + YubiKey PIV |
| Disk | [disko](https://github.com/nix-community/disko) — LUKS2 + BTRFS |
| Hosts | `bastion` (personal laptop) · `forge` (work laptop) |

## Structure

```
hosts/          per-machine config (hardware, host-specific services)
modules/        reusable NixOS modules (core, desktop, work, security, ...)
home/           home-manager config per host + shared common modules
secrets/        agenix-encrypted secrets (age + YubiKey)
```

## If you're looking for inspiration

These repos are better starting points for your own config:

- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [nix-community/awesome-nix](https://github.com/nix-community/awesome-nix)

## License

[The Unlicense](UNLICENSE) — public domain, no strings attached.
