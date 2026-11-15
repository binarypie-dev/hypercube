#!/bin/bash
# Shared package configuration for all workflows
# This file defines package metadata, dependencies, and upstream sources

# Package upstream repositories (GitHub)
declare -gA PACKAGE_REPOS=(
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
    [zellij]="zellij-org/zellij"
    [alacritty]="alacritty/alacritty"

    # Other
    [quickshell]="quickshell-mirror/quickshell"
)

# Version source (release or tag, default is release)
declare -gA VERSION_SOURCES=(
    [quickshell]="tag"
)

# Version pins: only consider upstream versions starting with this prefix.
# Use when a dependent can't build against a newer major series yet.
declare -gA VERSION_PINS=(
)

# Package dependencies (for determining build order)
declare -gA PACKAGE_DEPS=(
    # No package currently depends on another one
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
    [zellij]=""
    [alacritty]=""
)

# Build batches (packages in same batch can build in parallel)
declare -gA BUILD_BATCHES=(
    [1]="eza starship lazygit quickshell livesys-scripts wifitui resvg yazi bluetui iamb meli lazyjournal lazysql resterm zellij alacritty"
)

# Export for use in other scripts
export PACKAGE_REPOS
export VERSION_SOURCES
export VERSION_PINS
export PACKAGE_DEPS
export BUILD_BATCHES
