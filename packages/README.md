# Hypercube COPR Package Setup Guide

This document lists all packages to configure in the `binarypie/hypercube` COPR repository.

## COPR Repository Settings

- **Project Name**: `hypercube`
- **Chroot Targets**: `fedora-43-x86_64`
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

## Priority 1: Hyprland Core Libraries

These must be built first as other packages depend on them.

### 1. hyprutils

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprutils` |
| Spec File | `hyprutils.spec` |
| Version | 0.11.0 |
| Dependencies | None (base library) |

---

### 2. hyprlang

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprlang` |
| Spec File | `hyprlang.spec` |
| Version | 0.6.7 |
| Dependencies | hyprutils |

---

### 3. hyprwayland-scanner

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprwayland-scanner` |
| Spec File | `hyprwayland-scanner.spec` |
| Version | 0.4.5 |
| Dependencies | None |

---

### 4. hyprgraphics

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprgraphics` |
| Spec File | `hyprgraphics.spec` |
| Version | 0.4.0 |
| Dependencies | hyprutils |

---

### 5. hyprcursor

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprcursor` |
| Spec File | `hyprcursor.spec` |
| Version | 0.1.13 |
| Dependencies | hyprlang |

---

### 6. hyprland-protocols

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprland-protocols` |
| Spec File | `hyprland-protocols.spec` |
| Version | 0.7.0 |
| Dependencies | None |

---

### 7. aquamarine

| Setting | Value |
|---------|-------|
| Subdir | `packages/aquamarine` |
| Spec File | `aquamarine.spec` |
| Version | 0.10.0 |
| Dependencies | hyprutils, hyprwayland-scanner |

---

### 8. hyprwire

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprwire` |
| Spec File | `hyprwire.spec` |
| Version | 0.2.1 |
| Dependencies | hyprutils |
| Notes | Wire protocol for IPC, required by hyprpaper |

---

### 9. hyprland-qt-support

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprland-qt-support` |
| Spec File | `hyprland-qt-support.spec` |
| Version | 0.1.0 |
| Dependencies | hyprlang |

---

### 10. glaze

| Setting | Value |
|---------|-------|
| Subdir | `packages/glaze` |
| Spec File | `glaze.spec` |
| Version | 6.1.0 |
| Dependencies | None (header-only library) |
| Notes | Provides glaze-static for hyprland |

---

### 11. uwsm

| Setting | Value |
|---------|-------|
| Subdir | `packages/uwsm` |
| Spec File | `uwsm.spec` |
| Version | 0.26.0 |
| Dependencies | None (Python-based, uses system packages) |
| Notes | Universal Wayland Session Manager, required by hyprland-uwsm subpackage |

---

## Priority 2: Hyprland Compositor & Tools

Build after core libraries are available.

### 12. hyprland

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprland` |
| Spec File | `hyprland.spec` |
| Version | 0.52.2 |
| Dependencies | aquamarine, hyprcursor, hyprgraphics, hyprlang, hyprutils, hyprwayland-scanner |

---

### 13. hyprlock

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprlock` |
| Spec File | `hyprlock.spec` |
| Version | 0.9.2 |
| Dependencies | hyprgraphics, hyprlang, hyprutils, hyprwayland-scanner |

---

### 14. hypridle

| Setting | Value |
|---------|-------|
| Subdir | `packages/hypridle` |
| Spec File | `hypridle.spec` |
| Version | 0.1.7 |
| Dependencies | hyprland-protocols, hyprlang, hyprutils, hyprwayland-scanner |

---

### 15. hyprpaper

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprpaper` |
| Spec File | `hyprpaper.spec` |
| Version | 0.8.1 |
| Dependencies | hyprgraphics, hyprlang, hyprtoolkit, hyprutils, hyprwayland-scanner, hyprwire |

---

### 16. xdg-desktop-portal-hyprland

| Setting | Value |
|---------|-------|
| Subdir | `packages/xdg-desktop-portal-hyprland` |
| Spec File | `xdg-desktop-portal-hyprland.spec` |
| Version | 1.3.11 |
| Dependencies | hyprland-protocols, hyprlang, hyprutils, hyprwayland-scanner |

---

### 17. hyprpolkitagent

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprpolkitagent` |
| Spec File | `hyprpolkitagent.spec` |
| Version | 0.1.3 |
| Dependencies | hyprutils, hyprland-qt-support |

---

### 18. hyprtoolkit

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprtoolkit` |
| Spec File | `hyprtoolkit.spec` |
| Version | 0.4.1 |
| Dependencies | aquamarine, hyprgraphics, hyprlang, hyprutils, hyprwayland-scanner |
| Notes | Modern C++ Wayland-native GUI toolkit for Hyprland utilities |

---

### 19. hyprland-guiutils

| Setting | Value |
|---------|-------|
| Subdir | `packages/hyprland-guiutils` |
| Spec File | `hyprland-guiutils.spec` |
| Version | 0.2.0 |
| Dependencies | aquamarine, hyprtoolkit, hyprlang, hyprutils |
| Notes | Successor to hyprland-qtutils. Provides dialog, donate-screen, run, update-screen, welcome utilities |

---

## Priority 3: CLI Tools

These have no hyprland dependencies and can be built in parallel.

### 20. eza

| Setting | Value |
|---------|-------|
| Subdir | `packages/eza` |
| Spec File | `eza.spec` |
| Version | 0.20.21 |
| Dependencies | None |

---

### 21. starship

| Setting | Value |
|---------|-------|
| Subdir | `packages/starship` |
| Spec File | `starship.spec` |
| Version | 1.24.1 |
| Dependencies | None |

---

### 22. lazygit

| Setting | Value |
|---------|-------|
| Subdir | `packages/lazygit` |
| Spec File | `lazygit.spec` |
| Version | 0.57.0 |
| Dependencies | None |

---

### 23. ghostty

| Setting | Value |
|---------|-------|
| Subdir | `packages/ghostty` |
| Spec File | `ghostty.spec` |
| Version | 1.2.3^git (main branch) |
| Dependencies | None |
| Notes | Building from main branch for zig 0.15.2 compatibility |

---

### 24. quickshell

| Setting | Value |
|---------|-------|
| Subdir | `packages/quickshell` |
| Spec File | `quickshell.spec` |
| Version | 0.2.1 |
| Dependencies | None |

---

### 25. livesys-scripts

| Setting | Value |
|---------|-------|
| Subdir | `packages/livesys-scripts` |
| Spec File | `livesys-scripts.spec` |
| Version | 0.9.1 |
| Dependencies | None |
| Notes | Source is from Pagure fork, not GitHub |

---

### 26. wifitui

| Setting | Value |
|---------|-------|
| Subdir | `packages/wifitui` |
| Spec File | `wifitui.spec` |
| Version | 0.9.0 |
| Dependencies | None |
| Notes | TUI for WiFi management, supports NetworkManager and iwd backends |

---

## Build Order Summary

To ensure dependencies are satisfied, build in this order:

**Batch 1** (no dependencies):
1. hyprutils
2. hyprwayland-scanner
3. hyprland-protocols
4. glaze
5. uwsm
6. eza
7. starship
8. lazygit
9. ghostty
10. quickshell
11. livesys-scripts
12. wifitui

**Batch 2** (depends on Batch 1):
1. hyprlang (needs hyprutils)
2. hyprgraphics (needs hyprutils)
3. hyprwire (needs hyprutils)
4. aquamarine (needs hyprutils, hyprwayland-scanner)

**Batch 3** (depends on Batch 2):
1. hyprcursor (needs hyprlang)
2. hyprland-qt-support (needs hyprlang)

**Batch 3** (depends on Batch 2):
1. hyprcursor (needs hyprlang)
2. hyprland-qt-support (needs hyprlang)

**Batch 4** (depends on Batch 3):
1. hyprland (needs aquamarine, hyprcursor, hyprgraphics, hyprlang, hyprutils, glaze)
2. hyprlock (needs hyprgraphics, hyprlang, hyprutils, hyprwayland-scanner)
3. hypridle (needs hyprland-protocols, hyprlang, hyprutils, hyprwayland-scanner)
4. hyprpaper (needs hyprgraphics, hyprlang, hyprtoolkit, hyprutils, hyprwayland-scanner, hyprwire)
5. xdg-desktop-portal-hyprland (needs hyprland-protocols, hyprlang, hyprutils, hyprwayland-scanner)
6. hyprpolkitagent (needs hyprutils, hyprland-qt-support)
7. hyprtoolkit (needs aquamarine, hyprgraphics, hyprlang, hyprutils, hyprwayland-scanner)

**Batch 5** (depends on Batch 4):
1. hyprland-guiutils (needs aquamarine, hyprtoolkit, hyprlang, hyprutils)

---

## Quick Reference Table

| # | Package | Subdir | Spec File | Version |
|---|---------|--------|-----------|---------|
| 1 | hyprutils | `packages/hyprutils` | `hyprutils.spec` | 0.11.0 |
| 2 | hyprlang | `packages/hyprlang` | `hyprlang.spec` | 0.6.7 |
| 3 | hyprwayland-scanner | `packages/hyprwayland-scanner` | `hyprwayland-scanner.spec` | 0.4.5 |
| 4 | hyprgraphics | `packages/hyprgraphics` | `hyprgraphics.spec` | 0.4.0 |
| 5 | hyprcursor | `packages/hyprcursor` | `hyprcursor.spec` | 0.1.13 |
| 6 | hyprland-protocols | `packages/hyprland-protocols` | `hyprland-protocols.spec` | 0.7.0 |
| 7 | aquamarine | `packages/aquamarine` | `aquamarine.spec` | 0.10.0 |
| 8 | hyprland-qt-support | `packages/hyprland-qt-support` | `hyprland-qt-support.spec` | 0.1.0 |
| 9 | glaze | `packages/glaze` | `glaze.spec` | 6.1.0 |
| 10 | uwsm | `packages/uwsm` | `uwsm.spec` | 0.23.3 |
| 11 | hyprland | `packages/hyprland` | `hyprland.spec` | 0.52.2 |
| 12 | hyprlock | `packages/hyprlock` | `hyprlock.spec` | 0.9.2 |
| 13 | hypridle | `packages/hypridle` | `hypridle.spec` | 0.1.7 |
| 14 | hyprpaper | `packages/hyprpaper` | `hyprpaper.spec` | 0.7.6 |
| 15 | xdg-desktop-portal-hyprland | `packages/xdg-desktop-portal-hyprland` | `xdg-desktop-portal-hyprland.spec` | 1.3.11 |
| 16 | hyprpolkitagent | `packages/hyprpolkitagent` | `hyprpolkitagent.spec` | 0.1.3 |
| 17 | hyprtoolkit | `packages/hyprtoolkit` | `hyprtoolkit.spec` | 0.4.1 |
| 18 | hyprland-guiutils | `packages/hyprland-guiutils` | `hyprland-guiutils.spec` | 0.2.0 |
| 19 | eza | `packages/eza` | `eza.spec` | 0.20.21 |
| 20 | starship | `packages/starship` | `starship.spec` | 1.24.1 |
| 21 | lazygit | `packages/lazygit` | `lazygit.spec` | 0.57.0 |
| 22 | ghostty | `packages/ghostty` | `ghostty.spec` | 1.2.3^git |
| 23 | quickshell | `packages/quickshell` | `quickshell.spec` | 0.2.1 |
| 24 | livesys-scripts | `packages/livesys-scripts` | `livesys-scripts.spec` | 0.9.1 |
| 25 | wifitui | `packages/wifitui` | `wifitui.spec` | 0.9.0 |
