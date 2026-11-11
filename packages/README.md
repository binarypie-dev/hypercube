# Hypercube COPR Package Setup Guide

This document lists all packages to configure in the `binarypie/hypercube` COPR repository.

## COPR Repository Settings

- **Project Name**: `hypercube`
- **Chroot Targets**: `fedora-44-x86_64`
- **Build Method**: SCM (Source Control Management)

---

## Package Definitions

For each package, use these settings in COPR:

- **Type**: SCM
- **Clone URL**: `https://github.com/binarypie-dev/hypercube.git`
- **Committish**: `main`
- **Subdir**: (as listed below)
- **Spec File**: (as listed below)
- **SCM Type**: git

---

## Packages

None of these depend on each other, so they can all be built in parallel.

### 1. eza

| Setting | Value |
|---------|-------|
| Subdir | `packages/eza` |
| Spec File | `eza.spec` |
| Version | 0.20.21 |
| Dependencies | None |

---

### 2. starship

| Setting | Value |
|---------|-------|
| Subdir | `packages/starship` |
| Spec File | `starship.spec` |
| Version | 1.24.1 |
| Dependencies | None |

---

### 3. lazygit

| Setting | Value |
|---------|-------|
| Subdir | `packages/lazygit` |
| Spec File | `lazygit.spec` |
| Version | 0.57.0 |
| Dependencies | None |

---

### 4. ghostty

| Setting | Value |
|---------|-------|
| Subdir | `packages/ghostty` |
| Spec File | `ghostty.spec` |
| Version | 1.2.3^git (main branch) |
| Dependencies | None |
| Notes | Building from main branch for zig 0.15.2 compatibility |

---

### 5. quickshell

| Setting | Value |
|---------|-------|
| Subdir | `packages/quickshell` |
| Spec File | `quickshell.spec` |
| Version | 0.2.1 |
| Dependencies | None |

---

### 6. livesys-scripts

| Setting | Value |
|---------|-------|
| Subdir | `packages/livesys-scripts` |
| Spec File | `livesys-scripts.spec` |
| Version | 0.9.1 |
| Dependencies | None |
| Notes | Source is from Pagure fork, not GitHub |

---

### 7. wifitui

| Setting | Value |
|---------|-------|
| Subdir | `packages/wifitui` |
| Spec File | `wifitui.spec` |
| Version | 0.9.0 |
| Dependencies | None |
| Notes | TUI for WiFi management, supports NetworkManager and iwd backends |

---

### 8. resvg

| Setting | Value |
|---------|-------|
| Subdir | `packages/resvg` |
| Spec File | `resvg.spec` |
| Version | 0.46.0 |
| Dependencies | None |
| Notes | SVG rendering library and CLI tool, used by yazi for SVG previews |

---

### 9. yazi

| Setting | Value |
|---------|-------|
| Subdir | `packages/yazi` |
| Spec File | `yazi.spec` |
| Version | 26.1.22 |
| Dependencies | None |
| Notes | Terminal file manager written in Rust. Recommends resvg for SVG previews |

---

### 10. bluetui

| Setting | Value |
|---------|-------|
| Subdir | `packages/bluetui` |
| Spec File | `bluetui.spec` |
| Version | 0.8.1 |
| Dependencies | None |
| Notes | TUI for managing Bluetooth devices. Requires bluez at runtime |

---

### 11. iamb

| Setting | Value |
|---------|-------|
| Subdir | `packages/iamb` |
| Spec File | `iamb.spec` |
| Version | 0.0.11 |
| Dependencies | None |
| Notes | Matrix chat client with Vim-like keybindings |

---

### 12. meli

| Setting | Value |
|---------|-------|
| Subdir | `packages/meli` |
| Spec File | `meli.spec` |
| Version | 0.8.13 |
| Dependencies | None |
| Notes | Terminal email client. Source from git.meli-email.org, not GitHub |

---

### 13. lazyjournal

| Setting | Value |
|---------|-------|
| Subdir | `packages/lazyjournal` |
| Spec File | `lazyjournal.spec` |
| Version | 0.8.4 |
| Dependencies | None |
| Notes | TUI for viewing journalctl, Docker, Podman, and Kubernetes logs |

---

### 14. lazysql

| Setting | Value |
|---------|-------|
| Subdir | `packages/lazysql` |
| Spec File | `lazysql.spec` |
| Version | 0.4.6 |
| Dependencies | None |
| Notes | TUI database client for PostgreSQL, MySQL, SQLite, MSSQL |

---

### 15. resterm

| Setting | Value |
|---------|-------|
| Subdir | `packages/resterm` |
| Spec File | `resterm.spec` |
| Version | 0.20.3 |
| Dependencies | None |
| Notes | TUI REST, gRPC, and WebSocket API client |

---

### 16. zellij

| Setting | Value |
|---------|-------|
| Subdir | `packages/zellij` |
| Spec File | `zellij.spec` |
| Version | 0.44.3 |
| Dependencies | None |
| Notes | Terminal workspace/multiplexer. **Requires "Enable internet access during builds"** (bootstraps rustup + cargo fetches crates). Builds with a rustup-managed toolchain driven by the source's `rust-toolchain.toml`, so it tracks the latest stable zellij regardless of Fedora's Rust version. |

---

### 17. alacritty

| Setting | Value |
|---------|-------|
| Subdir | `packages/alacritty` |
| Spec File | `alacritty.spec` |
| Version | 0.17.0 |
| Dependencies | None |
| Notes | OpenGL terminal emulator (Rust). **Requires "Enable internet access during builds"** (cargo fetches crates). Builds with Fedora's rust/cargo. Packages terminfo (alacritty + alacritty-direct), desktop entry, man pages, and shell completions. |

---

## Build Order Summary

All packages build in a single batch (no inter-package dependencies):

1. eza
2. starship
3. lazygit
4. ghostty
5. quickshell
6. livesys-scripts
7. wifitui
8. resvg
9. yazi
10. bluetui
11. iamb
12. meli
13. lazyjournal
14. lazysql
15. resterm
16. zellij
17. alacritty

---

## Quick Reference Table

| # | Package | Subdir | Spec File | Version |
|---|---------|--------|-----------|---------|
| 1 | eza | `packages/eza` | `eza.spec` | 0.20.21 |
| 2 | starship | `packages/starship` | `starship.spec` | 1.24.1 |
| 3 | lazygit | `packages/lazygit` | `lazygit.spec` | 0.57.0 |
| 4 | ghostty | `packages/ghostty` | `ghostty.spec` | 1.2.3^git |
| 5 | quickshell | `packages/quickshell` | `quickshell.spec` | 0.2.1 |
| 6 | livesys-scripts | `packages/livesys-scripts` | `livesys-scripts.spec` | 0.9.1 |
| 7 | wifitui | `packages/wifitui` | `wifitui.spec` | 0.9.0 |
| 8 | resvg | `packages/resvg` | `resvg.spec` | 0.46.0 |
| 9 | yazi | `packages/yazi` | `yazi.spec` | 26.1.22 |
| 10 | bluetui | `packages/bluetui` | `bluetui.spec` | 0.8.1 |
| 11 | iamb | `packages/iamb` | `iamb.spec` | 0.0.11 |
| 12 | meli | `packages/meli` | `meli.spec` | 0.8.13 |
| 13 | lazyjournal | `packages/lazyjournal` | `lazyjournal.spec` | 0.8.4 |
| 14 | lazysql | `packages/lazysql` | `lazysql.spec` | 0.4.6 |
| 15 | resterm | `packages/resterm` | `resterm.spec` | 0.20.3 |
| 16 | zellij | `packages/zellij` | `zellij.spec` | 0.44.3 |
| 17 | alacritty | `packages/alacritty` | `alacritty.spec` | 0.17.0 |
