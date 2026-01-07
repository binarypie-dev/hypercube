# My Neovim Configuration

This is my personal Neovim configuration, based on [LazyVim](https://github.com/LazyVim/LazyVim).

## Overview

This configuration is built upon the LazyVim distribution and customized with a set of plugins and settings to enhance the development workflow.

## Distrobox Development Environment

A pre-built containerized Neovim environment is available via distrobox. The image includes all LSPs, formatters, linters, and language runtimes pre-installed.

### Quick Start (Hypercube Users)

```bash
# One command to set everything up
just nvim-setup

# Now use nvim directly
nvim file.rs
```

### Quick Start (Any Distrobox User)

```bash
# Pull the pre-built image
distrobox create --name nvim-dev --image ghcr.io/binarypie/nvim-dev:latest

# Export nvim to your PATH
distrobox enter nvim-dev -- distrobox-export --bin /home/linuxbrew/.linuxbrew/bin/nvim --export-path ~/.local/bin

# Use nvim directly
nvim file.rs
```

### Available Commands (Hypercube)

| Command | Description |
|---------|-------------|
| `just nvim-setup` | Create container + export nvim (one-time setup) |
| `just nvim-dev` | Enter the container interactively |
| `just nvim-export` | Export nvim to ~/.local/bin |
| `just nvim-upgrade` | Upgrade container to latest image |

### Local Development

For testing changes to the container image:

```bash
cd dot_files/nvim

just build        # Build image locally
just setup-local  # Create container from local image + export
just test-build   # Verify all tools are installed
just clean        # Remove container
```

### What's Pre-Installed

The container image (`ghcr.io/binarypie/nvim-dev`) includes:

**Languages & Runtimes:**
- Go, Python 3.12, Node.js, Ruby, Lua, Rust

**Formatters:**
- stylua, prettier, shfmt, gofumpt, goimports, black, isort, ruff

**Linters:**
- shellcheck, hadolint, eslint, golangci-lint

**Language Servers:**
- lua-language-server, gopls, pyright, typescript-language-server, vtsls, rust-analyzer, bash-language-server, dockerfile-language-server, yaml-language-server, tailwindcss-language-server

**Infrastructure Tools:**
- terraform, tflint, helm, sqlfluff

**CLI Tools:**
- ripgrep, fd, fzf, lazygit, gh, bat, eza, delta, jq, yq

**Other:**
- Tree-sitter CLI
- Ghostty terminal support (terminfo)
- Fish shell

### How It Works

The pre-built image is published to GitHub Container Registry and rebuilt automatically when the Containerfile changes. Users pull the ~2GB image once, then container creation is instant.

Unlike Docker containers, distrobox provides seamless integration:
- Your `~/.config/nvim` is directly accessible
- Git credentials, SSH keys, GPG keys all work automatically
- Clipboard works via OSC 52
- The exported `nvim` command transparently enters the container

### Updating

```bash
# Update to latest image
just nvim-upgrade

# Or manually
distrobox upgrade nvim-dev
```

## Plugins

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) to manage plugins.

### Core Plugins (from LazyVim)

* LazyVim, blink.cmp, bufferline.nvim, conform.nvim, flash.nvim
* gitsigns.nvim, grug-far.nvim, lazy.nvim, lazydev.nvim, lualine.nvim
* mason.nvim, mason-lspconfig.nvim, mini.ai, mini.icons, mini.pairs
* noice.nvim, nvim-lint, nvim-lspconfig, nvim-treesitter
* persistence.nvim, snacks.nvim, todo-comments.nvim, tokyonight.nvim
* trouble.nvim, which-key.nvim, yanky.nvim

### Language-Specific

* rustaceanvim, crates.nvim, vim-helm
* vim-dadbod, vim-dadbod-ui, vim-dadbod-completion

## Installation (Without Container)

1. Clone this repository to `~/.config/nvim`
2. Delete the .git folder
3. Start Neovim - lazy.nvim will install plugins automatically
