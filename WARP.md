# WARP.md

This file provides guidance to a Large Language Model (LLM) when working with code in this repository.

## Architecture Overview

This is a **NixOS flake-based configuration** for a cyberpunk-themed desktop system using **COSMIC DE**. The configuration is structured as a single-host setup with modular organization.

### Core Structure

- **Flake-based**: Uses `flake.nix` as the entry point with `nixos-unstable`.
- **Single host configuration**: `nixosConfigurations.nixos` for the main system.
- **Home Manager integration**: User-space configuration managed through `home-manager`.
- **Modular design**: System and home configurations are split into focused modules.

### System Configuration Flow

```
flake.nix → nixosConfigurations.nixos → modules:
├── default/configuration.nix (base system config)
├── default/hardware-configuration.nix (hardware-specific)
├── local/local-hardware.nix (machine-specific, git-ignored)
├── packages.nix (system packages)
├── modules.nix (imports modules/de.nix)
└── cache.nix (nix cache settings)
```

### Home Manager Flow

```
home-manager/home.nix → modules:
├── helix.nix (editor config)
├── warp-terminal.nix (terminal theme)
├── de.nix (COSMIC desktop settings)
├── git.nix, yazi.nix, btop.nix, etc.
```

### Important Design Decisions

- **Local Hardware Handling**: Each machine needs a `local/local-hardware.nix` file, which is git-ignored. The `flake.nix` file uses an absolute path to this file, which requires the use of the `--impure` flag when building the system. To use this configuration on a different machine, the absolute path in `flake.nix` must be updated.
- **Cyberpunk Theme**: Custom GRUB theme (CyberGRUB-2077), COSMIC theme file, Plymouth spinner theme, and a terminal color scheme.
- **COSMIC DE**: Uses the new System76 COSMIC desktop environment with Wayland.
- **Terminal:** The primary terminal is `foot`, with `Warp` as a fallback.
- **Flake Inputs**: Custom inputs for `warp-terminal-theme`, `zen-browser`, and `cosmic-manager`.

## Common Commands

### System Management

**Rebuild system configuration:**
```bash
sudo nixos-rebuild switch --flake . --impure
```

**Test configuration without switching:**
```bash
sudo nixos-rebuild test --flake . --impure
```

**Build configuration without applying:**
```bash
sudo nixos-rebuild build --flake . --impure
```

**Boot into new configuration on next reboot:**
```bash
sudo nixos-rebuild boot --flake . --impure
```

### Flake Operations

**Update flake inputs:**
```bash
nix flake update
```

**Show flake info:**
```bash
nix flake show
```

**Check flake for issues:**
```bash
nix flake check
```

### Home Manager Operations

**Apply home-manager changes:**
```bash
home-manager switch --flake .
```

**Build home configuration:**
```bash
nix build .#homeConfigurations.necryl.activationPackage
```

### Development Workflow

**Edit configuration files:**
- Primary editor: `hx` (Helix)
- File manager: `yazi` or Dolphin
- Terminal: `foot` (primary), `warp-terminal` (fallback)

**Quick system info:**
```bash
neofetch
```

## Local Hardware Setup

For new machines:

1.  Create a `local/local-hardware.nix` file. You can use `local/local-hardware-template.nix.sample` as a template.
2.  Generate a hardware configuration for your system using `nixos-generate-config` and add it to the file.
3.  Update the absolute path to `local/local-hardware.nix` in `flake.nix`.

Note: The current setup requires the `--impure` flag due to the absolute path usage in `flake.nix`.

## Key Technologies

- **OS**: NixOS 24.11 with flakes
- **Desktop**: COSMIC DE (System76's new desktop environment)
- **Display Protocol**: Wayland with XWayland support
- **Bootloader**: GRUB with custom CyberGRUB theme
- **Package Management**: Nix flakes + Home Manager
- **Editor**: Helix with LSP support
- **Terminal**: `foot` (primary), `warp-terminal` (fallback)
- **File Manager**: Yazi (TUI) + Dolphin (GUI)
- **Containerization**: Podman with Docker compatibility

## Utility Scripts

- **`utility_scripts/onedrive.sh`**: Toggle OneDrive mounting via rclone.
- **`utility_scripts/cliphist_wofi.sh`**: Clipboard history viewer with `wofi`.
- **`utility_scripts/tmux-ide.sh`**: Sets up a `tmux` session for development.

## Development Stack

**Language Servers configured in `helix.nix`:**
- svelteserver
- typescript-language-server
- vscode-json-language-server
- emmet-lsp
- astro-ls

**Package managers available:**
- pnpm (preferred for Node.js projects)
- npm (via nodejs package)

**Container tools:**
- Podman (Docker-compatible)
- Distrobox for containerized development environments

## Notes

- **`xdg.nix`:** The file `home-manager/modules/xdg.nix` is currently commented out and not in use.
- **Themes:** The Cosmic DE theme in `CosmicCyberpunkDarkTheme.ron` must be manually imported in the Cosmic DE settings. The cursor theme in `WinSur-white-cursors` is not yet implemented.