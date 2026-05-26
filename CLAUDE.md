# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Apply system configuration (current host)
sudo nh os switch

# Apply for a specific host
sudo nixos-rebuild switch --flake .#bastion
sudo nixos-rebuild switch --flake .#forge

# Dry-run (preview changes without applying)
sudo nixos-rebuild dry-activate --flake .#<hostname>

# Format all Nix files
nix fmt

# Lint (run manually; CI uses statix + deadnix + alejandra)
nix run nixpkgs#statix -- check .
nix run nixpkgs#deadnix -- .

# Edit an agenix secret (requires YubiKey)
nix run .#edit-secret -- secrets/<name>.age

# Rekey all secrets (after adding a new host or key)
nix run .#rekey

```

## Architecture

### Flake Structure
- `flake.nix`: Defines inputs (nixpkgs `nixos-25.11`, `nixpkgs-unstable`, `home-manager`, `disko`, `agenix`, `lanzaboote`, `hyprpanel`, `neovim-nightly-overlay`) and all system outputs via a `mkHost` helper function.
- All systems are built with `mkHost`, which wires together a NixOS host module, a home-manager module, disk config, and special args (unstable pkgs, hyprpanel, vscode extensions).

### Hosts
- **`bastion`** — personal laptop, user `gast`, Intel GPU, single HiDPI monitor
- **`forge`** — work laptop, user `serobja`, Intel + NVIDIA GPU, 3-monitor setup; has additional work modules (VPN, certs, DNS, Docker registries)

### Module Layout
- `modules/core/` — users, boot (lanzaboote), disko, nix settings, nh cleanup
- `modules/desktop/` — Hyprland, SDDM, audio (PipeWire), Bluetooth, power management
- `modules/dev/` — Docker, Node, Python, PHP, editors
- `modules/hardware/` — Intel, NVIDIA, Thunderbolt dock
- `modules/security/` — YubiKey (PIV + FIDO2), agenix
- `modules/work/` — VPN, internal CAs, DNS, private Docker registries, work apps
- `modules/compat/` — distrobox, nix-ld
- `home/common/` — shared home-manager config (zsh, neovim-nightly, VS Code, Hyprland, rofi, kitty, starship, etc.)
- `home/bastion.nix` / `home/forge.nix` — per-host home-manager entrypoints

### Package Strategy
- Stable `nixpkgs` (`nixos-25.11`) for system packages
- `nixpkgs-unstable` for: Hyprland, HyprPanel, neovim (nightly overlay), VS Code, claude-code, and other fast-moving tools
- `nix-vscode-extensions` for declarative VS Code extension management

### Secrets (agenix)
- All secrets are age-encrypted in `secrets/*.age`
- `secrets/secrets.nix` maps each secret to the public keys that can decrypt it (two YubiKey masters + per-host SSH keys)
- Secrets are available at runtime under `/run/agenix.d/<name>`
- Adding a new secret: add entry to `secrets/secrets.nix`, run `nix run .#edit-secret`, then `nix run .#rekey`

### Disk / Boot
- **Disko**: LUKS2-encrypted BTRFS with subvolumes (`@`, `@home`, `@nix`, `@log`, `@swap`)
- **Lanzaboote**: Secure Boot (keys enrolled post-install via `sbctl`)
- **Hibernation**: Resume offset must be calculated per machine and set in `hosts/<name>/default.nix`
- **FIDO2**: YubiKey LUKS unlock via `systemd-cryptenroll` (passphrase fallback kept)

### Theming
- GTK: Catppuccin Mocha Mauve (dark)
- Color generation: Matugen derives palette from wallpaper, applied to HyprPanel and other components
- Fonts: JetBrainsMono Nerd Font (mono), Noto (sans/serif), Fira Code

## Formatting & Linting
The formatter is `alejandra` (set as `flake.formatter`). Linting is done with `statix` (idiomatic Nix checks) and `deadnix` (dead code). Run `nix fmt` before committing.

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
