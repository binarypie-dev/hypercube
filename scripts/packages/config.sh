#!/bin/bash
# Shared package configuration for all workflows
# This file defines package metadata, dependencies, and upstream sources

# Package upstream repositories (GitHub)
declare -gA PACKAGE_REPOS=(
    # Hyprland ecosystem
    [hyprutils]="hyprwm/hyprutils"
    [hyprlang]="hyprwm/hyprlang"
    [hyprwayland-scanner]="hyprwm/hyprwayland-scanner"
    [hyprgraphics]="hyprwm/hyprgraphics"
    [hyprcursor]="hyprwm/hyprcursor"
    [hyprland-protocols]="hyprwm/hyprland-protocols"
    [hyprwire]="hyprwm/hyprwire"
    [aquamarine]="hyprwm/aquamarine"
    [hyprland-qt-support]="hyprwm/hyprland-qt-support"
    [hyprland]="hyprwm/Hyprland"
    [hyprlock]="hyprwm/hyprlock"
    [hypridle]="hyprwm/hypridle"
    [hyprpaper]="hyprwm/hyprpaper"
    [xdg-desktop-portal-hyprland]="hyprwm/xdg-desktop-portal-hyprland"
    [hyprpolkitagent]="hyprwm/hyprpolkitagent"
    [hyprtoolkit]="hyprwm/hyprtoolkit"
    [hyprland-guiutils]="hyprwm/hyprland-guiutils"

    # CLI tools
    [eza]="eza-community/eza"
    [starship]="starship/starship"
    [lazygit]="jesseduffield/lazygit"
    [wifitui]="shazow/wifitui"
    [yazi]="sxyazi/yazi"
    [resvg]="linebender/resvg"
    [bluetui]="pythops/bluetui"
    [iamb]="ulyssa/iamb"
    [lazyjournal]="Lifailon/lazyjournal"
    [lazysql]="jorgerojas26/lazysql"
    [resterm]="unkn0wn-root/resterm"

    # Other
    [glaze]="stephenberry/glaze"
    [uwsm]="Vladimir-csp/uwsm"
    [quickshell]="quickshell-mirror/quickshell"
)

# Version source (release or tag, default is release)
declare -gA VERSION_SOURCES=(
    [uwsm]="tag"
    [quickshell]="tag"
)

# Package dependencies (for determining build order)
declare -gA PACKAGE_DEPS=(
    # Base packages with no dependencies
    [hyprutils]=""
    [hyprwayland-scanner]=""
    [hyprland-protocols]=""
    [hyprwire]=""
    [glaze]=""
    [uwsm]=""
    [eza]=""
    [starship]=""
    [lazygit]=""
    [quickshell]=""
    [livesys-scripts]=""
    [wifitui]=""
    [resvg]=""
    [yazi]=""
    [bluetui]=""
    [iamb]=""
    [meli]=""
    [lazyjournal]=""
    [lazysql]=""
    [resterm]=""

    # Packages with dependencies
    [hyprlang]="hyprutils"
    [hyprgraphics]="hyprutils"
    [aquamarine]="hyprutils hyprwayland-scanner"
    [hyprcursor]="hyprlang"
    [hyprland-qt-support]="hyprlang"
    [hyprland]="aquamarine hyprcursor hyprgraphics hyprlang hyprutils hyprwire glaze"
    [hyprlock]="hyprgraphics hyprlang hyprutils hyprwayland-scanner"
    [hypridle]="hyprland-protocols hyprlang hyprutils hyprwayland-scanner"
    [hyprpaper]="hyprgraphics hyprlang hyprutils hyprwayland-scanner hyprwire hyprtoolkit"
    [xdg-desktop-portal-hyprland]="hyprland-protocols hyprlang hyprutils hyprwayland-scanner"
    [hyprpolkitagent]="hyprutils hyprland-qt-support"
    [hyprtoolkit]="aquamarine hyprgraphics hyprlang hyprutils hyprwayland-scanner"
    [hyprland-guiutils]="aquamarine hyprtoolkit hyprlang hyprutils"
)

# Build batches (packages in same batch can build in parallel)
declare -gA BUILD_BATCHES=(
    [1]="hyprutils hyprwayland-scanner hyprland-protocols hyprwire glaze uwsm eza starship lazygit quickshell livesys-scripts wifitui resvg yazi bluetui iamb meli lazyjournal lazysql resterm"
    [2]="hyprlang hyprgraphics aquamarine"
    [3]="hyprcursor hyprland-qt-support"
    [4]="hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprtoolkit"
    [5]="hyprpaper hyprland-guiutils"
)

# Export for use in other scripts
export PACKAGE_REPOS
export VERSION_SOURCES
export PACKAGE_DEPS
export BUILD_BATCHES
