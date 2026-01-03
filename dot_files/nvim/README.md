# My Neovim Configuration

This is my personal Neovim configuration, based on [LazyVim](https://github.com/LazyVim/LazyVim).

## Overview

This configuration is built upon the LazyVim distribution and customized with a set of plugins and settings to enhance the development workflow.

## Docker Development Environment

A fully containerized Neovim environment is available for portable, consistent development across machines.

### Quick Start

```bash
# Build the container
just build

# Configure shell alias (adds 'nvimd' to your shell)
just shell-config

# Restart your shell or source your config, then:
nvimd                    # Open nvim in current directory
nvimd ~/projects/myapp   # Open nvim in specific directory
nvimd file.txt           # Open specific file
```

### Requirements

- Docker
- [just](https://github.com/casey/just) command runner

### Available Commands

| Command | Description |
|---------|-------------|
| `just build` | Build the Docker image (uses layer cache) |
| `just rebuild` | Force rebuild without cache |
| `just rebuild-clean` | Remove old image and rebuild fresh |
| `just run [args]` | Run nvim in current directory |
| `just shell` | Open a bash shell in the container (debugging) |
| `just info` | Show image info (size, creation date) |
| `just clean` | Remove the Docker image |
| `just shell-config` | Add `nvimd` alias to your shell config |

### What's Included

The Docker image is based on Fedora and includes:

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
- Tree-sitter CLI and pre-installed parsers
- Ghostty terminal support (terminfo)
- Fish shell (for fish_indent formatter)

### Volume Mounts

The container mounts your local directories:

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/home/nvim/.config/nvim` | `~/.config/nvim` | Config (read-only) |
| `/home/nvim/.local/share/nvim` | `~/.local/share/nvim` | Plugin data |
| `/home/nvim/.local/state/nvim` | `~/.local/state/nvim` | State files |
| `/home/nvim/.cache/nvim` | `~/.cache/nvim` | Cache |
| `/workspace` | Current directory | Your code |

### Clipboard Support

The container uses OSC 52 for clipboard integration, which works with modern terminals like Ghostty, Kitty, and others that support OSC 52 escape sequences.

## Plugins

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) to manage plugins. Here is a list of the plugins included in this configuration:

### Core Plugins (from LazyVim)

* LazyVim
* blink.cmp 
* bufferline.nvim
* catppuccin 
* conform.nvim 
* crates.nvim 
* dial.nvim 
* flash.nvim
* friendly-snippets 
* gitsigns.nvim 
* grug-far.nvim 
* inc-rename.nvim 
* lazy.nvim
* lazydev.nvim 
* lualine.nvim
* mason-lspconfig.nvim 
* mason.nvim 
* mini.ai
* mini.hipatterns 
* mini.icons 
* mini.pairs
* noice.nvim
* nui.nvim
* nvim-lint
* nvim-lspconfig 
* nvim-treesitter
* nvim-treesitter-textobjects
* nvim-ts-autotag 
* persistence.nvim
* plenary.nvim
* rustaceanvim 
* snacks.nvim
* todo-comments.nvim
* tokyonight.nvim
* trouble.nvim
* ts-comments.nvim
* vim-dadbod 
* vim-dadbod-completion 
* vim-dadbod-ui 
* vim-helm 
* which-key.nvim
* yanky.nvim

 ### Custom Plugins and Configuration

The following customizations have been applied.

* Augment Code 

## How it Works

This configuration is loaded from `init.lua`, which bootstraps `lazy.nvim` and the rest of the configuration. The main configuration is in `lua/config/lazy.lua`, which sets up `lazy.nvim` and loads the plugins.

The plugins are defined in `lua/plugins/`. The file `lua/plugins/example.lua` contains the custom plugin configurations. Any file in this directory is automatically loaded by `lazy.nvim`.

The `lazy-lock.json` file is used to lock the versions of the plugins, ensuring that the configuration is reproducible.

## Installation

1.  Clone this repository to `~/.config/nvim`.
2.  Delete the .git folder
3.  Start Neovim. `lazy.nvim` will automatically install the plugins.
