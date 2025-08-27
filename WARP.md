# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Architecture Overview

This is a **NixOS flake-based configuration** for a cyberpunk-themed desktop system using **COSMIC DE**. The configuration is structured as a single-host setup with modular organization.

### Core Structure

- **Flake-based**: Uses `flake.nix` as the entry point with nixos-unstable
- **Single host configuration**: `nixosConfigurations.nixos` for the main system
- **Home Manager integration**: User-space configuration managed through home-manager
- **Modular design**: System and home configurations split into focused modules

### Key Architecture Components

**System Configuration Flow:**
```
flake.nix → nixosConfigurations.nixos → modules:
├── default/configuration.nix (base system config)
├── default/hardware-configuration.nix (hardware-specific)
├── local/local-hardware.nix (machine-specific, git-ignored)
├── packages.nix (system packages)
├── modules.nix (imports modules/de.nix)
└── cache.nix (nix cache settings)
```

**Home Manager Flow:**
```
home-manager/home.nix → modules:
├── helix.nix (editor config)
├── warp-terminal.nix (terminal theme)
├── de.nix (COSMIC desktop settings)
├── git.nix, yazi.nix, btop.nix, etc.
```

### Important Design Decisions

- **Local Hardware Handling**: Each machine needs `local/local-hardware.nix` (gitignored). Current workaround uses absolute path `/home/necryl/nixos-config/local/local-hardware.nix` with `--impure` flag
- **Cyberpunk Theme**: Custom GRUB theme (CyberGRUB-2077), COSMIC theme file, Plymouth spinner theme
- **COSMIC DE**: Uses the new System76 COSMIC desktop environment with Wayland
- **Flake Inputs**: Custom inputs for warp-terminal theme, zen-browser, and cosmic-manager

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
- Terminal: Warp Terminal

**Quick system info:**
```bash
neofetch
```

## Local Hardware Setup

For new machines, copy and modify the hardware template:
```bash
cp local/local-hardware-template.nix.sample local/local-hardware.nix
# Edit local/local-hardware.nix with machine-specific hardware configuration
```

Note: The current setup requires the `--impure` flag due to absolute path usage in flake.nix line 61.

## Key Technologies

- **OS**: NixOS 24.11 with flakes
- **Desktop**: COSMIC DE (System76's new desktop environment)
- **Display Protocol**: Wayland with XWayland support
- **Bootloader**: GRUB with custom CyberGRUB theme
- **Package Management**: Nix flakes + Home Manager
- **Editor**: Helix with LSP support (Svelte, TypeScript, JSON, Emmet)
- **Terminal**: Warp Terminal with custom theme
- **File Manager**: Yazi (TUI) + Dolphin (GUI)
- **Containerization**: Podman with Docker compatibility

## Utility Scripts

**OneDrive Management:**
- `utility_scripts/onedrive.sh`: Toggle OneDrive mounting via rclone
- Related scripts for opening OneDrive in browser/Edge

## Development Stack

**Language Servers configured:**
- Svelte Language Server
- TypeScript Language Server  
- JSON Language Server
- Emmet Language Server

**Package managers available:**
- pnpm (preferred for Node.js projects)
- npm (via nodejs package)

**Container tools:**
- Podman (Docker-compatible)
- Distrobox for containerized development environments
