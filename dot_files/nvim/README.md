# Hypercube Neovim — AI-first sandbox

A self-contained, **portable** Neovim environment: [LazyVim](https://github.com/LazyVim/LazyVim)
plus the full dev toolchain (LSPs/formatters/linters) **and** AI coding agents,
all baked into one podman image. Launch the agents from inside nvim.

Runs identically on the Hypercube Linux desktop, a remote box, and macOS — no
distrobox required.

## What's baked in

- **Editor:** Neovim + LazyVim with Hypercube customizations.
- **AI agents:** Claude Code (`claude`), OpenAI Codex (`codex`), Antigravity
  (`agy`), GitHub CLI (`gh`). Wired into nvim via `claudecode.nvim` and
  `sidekick.nvim`.
- **Languages & runtimes:** Go, Python 3.12, Node.js, Ruby, Lua, Rust.
- **Formatters:** stylua, prettier, shfmt, gofumpt, goimports, black, isort, ruff.
- **Linters:** shellcheck, hadolint, eslint, golangci-lint.
- **Language servers:** lua-language-server, gopls, pyright,
  typescript-language-server, vtsls, rust-analyzer, bash-language-server,
  dockerfile-language-server, yaml-language-server, tailwindcss-language-server.
- **CLI tools:** ripgrep, fd, fzf, lazygit, bat, eza, delta, jq, yq, just,
  tree-sitter; Ghostty terminfo; fish.

## How it works

`scripts/nvim.sh` runs the image as an ephemeral `podman` container and mounts
only what's needed:

| Mounted in | Purpose |
|---|---|
| named volume `hypercube-nvim-home` → `/root` | plugin/mason updates, sessions, shada, **and AI-CLI auth** — seeded from the image on first run, persisted after |
| current directory | the project you're editing |
| `~/.config/hypercube/nvim` | **your** plugin overrides, layered on top of the baked config |
| `~/.gitconfig` (ro) | commit identity |
| `$SSH_AUTH_SOCK` (Linux) | SSH agent for git/gh |

Everything else (the LazyVim config, plugins, AI CLIs) lives in the image. The
container runs as `--user 0:0` so files you edit are owned by your host user
under rootless podman. Multiple sessions run concurrently — there's no fixed
container name, and nvim safely shares shada/swap.

Clipboard uses **OSC 52** through the terminal, so yank/paste works locally
(Ghostty) and over SSH without forwarding a Wayland/pbcopy socket.

## Setup (Hypercube)

```bash
ujust nvim-setup     # pull image + install the 'nvim' wrapper to ~/.local/bin
nvim file.rs         # launch
```

| Command | Description |
|---------|-------------|
| `ujust nvim-setup`   | pull image + install the `nvim` wrapper |
| `ujust nvim-upgrade` | pull the latest image + refresh the wrapper |
| `ujust nvim-reset`   | drop the home volume to re-seed (clears plugin state + AI logins) |
| `ujust nvim-shell`   | debug shell inside a throwaway sandbox container |

## Setup (macOS / any podman host)

No `ujust` needed — install the wrapper by hand:

```bash
podman pull ghcr.io/binarypie-dev/nvim-dev:latest
install -m 0755 dot_files/nvim/scripts/nvim.sh ~/.local/bin/nvim
nvim
```

macOS notes:
- Edit projects under your home directory (the path podman's VM shares).
- The host SSH agent isn't reachable from the podman VM, so run `gh auth login`
  once inside nvim's terminal — it persists in the home volume and authenticates
  git over HTTPS.

## Personal overrides

Drop LazyVim plugin specs in `~/.config/hypercube/nvim/lua/plugins/*.lua`. They're
bind-mounted in and layered on top of the baked config — add plugins, change
options, or disable defaults without rebuilding the image. Example:

```lua
-- ~/.config/hypercube/nvim/lua/plugins/mine.lua
return {
  { "folke/snacks.nvim", opts = { dashboard = { preset = { header = "hi" } } } },
}
```

## AI keymaps

- `<leader>a…` — Claude Code (claudecode.nvim, LazyVim defaults)
- `<leader>A…` — sidekick.nvim agents: `Ac` Claude, `Ax` Codex, `Aa` toggle
  last, `As` send selection, `Ap` ask with prompt
- `<Tab>` — apply/jump sidekick Next Edit Suggestion (falls through to `<Tab>`
  when Copilot isn't signed in)

## Local development (editing the image)

```bash
cd dot_files/nvim

just build         # build localhost/nvim-dev
just test-build    # verify nvim + toolchain + AI CLIs run
just run .         # launch the local image (uses a throwaway test volume)
just shell         # bash in the local image
just clean-image   # remove the local image
```
