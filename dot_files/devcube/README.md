# devcube — containerized IDE + parallel-agent orchestration

A self-contained, **portable** development environment baked into one podman
image: [LazyVim](https://github.com/LazyVim/LazyVim), the full dev toolchain
(LSPs/formatters/linters), the AI coding agents, **and**
[zellij](https://github.com/zellij-org/zellij) + the **workbox** plugin
(`workbox/`) for running multiple agents in parallel — each in its own git
worktree, all inside a single container (no nested podman).

A single wrapper installed as `devc` runs it. Runs identically on the Hypercube
Linux desktop, a remote box, and macOS — no distrobox required.

## What's baked in

- **Editor:** Neovim + LazyVim with Hypercube customizations.
- **AI agents:** Claude Code (`claude`), OpenAI Codex (`codex`), Antigravity
  (`agy`), GitHub CLI (`gh`). Wired into nvim via `claudecode.nvim` and
  `sidekick.nvim`.
- **Parallel agents:** zellij (terminal multiplexer) + the workbox plugin
  (git-worktree → tab/agent orchestration, built from `workbox/`).
- **Seamless nav:** `Ctrl h/j/k/l` moves focus across zellij panes *and* nvim
  splits as one motion (workbox plugin ↔ smart-splits.nvim).
- **Shell:** fish + starship prompt (Tokyo Night Moon, matching nvim/Ghostty).
- **Languages & runtimes:** Go, Python 3.12, Node.js, Ruby, Lua, Rust.
- **Formatters:** stylua, prettier, shfmt, gofumpt, goimports, black, isort, ruff.
- **Linters:** shellcheck, hadolint, eslint, golangci-lint.
- **Language servers:** lua-language-server, gopls, pyright,
  typescript-language-server, vtsls, rust-analyzer, bash-language-server,
  dockerfile-language-server, yaml-language-server, tailwindcss-language-server.
- **CLI tools:** ripgrep, fd, fzf, lazygit, bat, eza, delta, jq, yq, just,
  tree-sitter; Ghostty terminfo.

## Usage

`devc` dispatches on its first argument (extra args pass through):

| Command | What it does |
|---|---|
| `devc`            | the workbox parallel-agent workspace (a zellij session) — the default |
| `devc zellij`     | a plain zellij multiplexer session |
| `devc nvim [file]`| the editor |
| `devc claude`     | Claude Code CLI, run directly |
| `devc codex`      | OpenAI Codex CLI, run directly |
| `devc agy`        | Antigravity CLI, run directly |

All entry points share one home volume, so an AI login from any of them works in
all of them.

### Parallel agents

Run `devc` (or `devc workbox`) to open the workbox workspace — a plugin
dashboard above a shell. From the shell pane (or from inside nvim, see below):

```bash
zellij pipe --name workbox-add    --args branch=<branch>,prompt="<prompt>"  # worktree + tab running the agent
zellij pipe --name workbox-list                                            # refresh the worktree list
zellij pipe --name workbox-merge  --args branch=<branch>                   # merge and clean up
zellij pipe --name workbox-remove --args branch=<branch>                   # remove without merging
```

From nvim the same actions are `:WorkboxAdd <branch> "<prompt>"`,
`:WorkboxList`, `:WorkboxMerge <branch>`, `:WorkboxRemove <branch>`. Each agent
worktree opens as its own zellij **tab**; switch with `Ctrl t` then `h/l` or
`1-9`, and move within a tab with `Ctrl h/j/k/l` (seamless into nvim splits).

Worktrees are created on a **per-project named volume** mounted at `/worktrees`,
so they persist across restarts and stay isolated from other projects. The
volume name is derived from the launch path, so `~/Code/myrepo` always gets the
same worktrees back. (Worktrees live on the volume, not on the host — manage
them from inside `devc`, not via `git worktree` on the host.)

## How it works

`scripts/devcube.sh` runs the image as an ephemeral `podman` container and mounts
only what's needed. The mounts:

| Mounted in | Purpose |
|---|---|
| named volume `hypercube-devcube-home` → `/root` | plugin/mason updates, sessions, shada, **and AI-CLI auth** — seeded from the image on first run, persisted after |
| current directory | the project you're editing |
| per-project volume `devcube-wt-<proj>-<hash>` → `/worktrees` | worktrees + per-project agent state (orchestrators only) |
| `~/.config/hypercube/nvim` | **your** plugin overrides, layered on top of the baked config |
| `~/.gitconfig` (ro) | commit identity |
| `$SSH_AUTH_SOCK` (Linux) | SSH agent for git/gh |

Everything else (the LazyVim config, plugins, AI CLIs, the workbox plugin,
zellij/fish/starship config) lives in the image. The container runs as
`--user 0:0` so files
you edit are owned by your host user under rootless podman. Multiple sessions run
concurrently.

Clipboard uses **OSC 52** through the terminal, so yank/paste works locally
(Ghostty) and over SSH without forwarding a Wayland/pbcopy socket.

## Setup (Hypercube)

```bash
ujust devcube-setup    # pull image + install the 'devc' wrapper to ~/.local/bin
devc                   # open the parallel-agent workspace
devc nvim file.rs      # ...or just the editor
```

| Command | Description |
|---------|-------------|
| `ujust devcube-setup`   | pull image + install the `devc` wrapper |
| `ujust devcube-upgrade` | pull the latest image + refresh the wrapper |
| `ujust devcube-reset`   | drop the home volume to re-seed (clears plugin state + AI logins); optionally prune per-project worktree volumes |
| `ujust devcube-shell`   | debug shell inside a throwaway container |

## Setup (macOS / any podman host)

No `ujust` needed — install the wrapper by hand:

```bash
podman pull ghcr.io/binarypie-dev/devcube:latest
install -m 0755 dot_files/devcube/scripts/devcube.sh ~/.local/bin/devc
devc
```

macOS notes:
- Edit projects under your home directory (the path podman's VM shares).
- The host SSH agent isn't reachable from the podman VM, so run `gh auth login`
  once inside (e.g. from `devc nvim`'s terminal) — it persists in the home volume
  and authenticates git over HTTPS.

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

The build context is the parent `dot_files/` dir (so the fish/starship/zellij/
nvim configs and the `devcube/workbox` plugin crate can be baked), which the
recipes handle for you:

```bash
cd dot_files/devcube

just build         # build localhost/devcube
just test-build    # verify nvim + toolchain + AI CLIs + zellij/fish/starship + workbox.wasm
just run           # launch the workbox workspace from the local image (throwaway volumes)
just run nvim .    # ...or a specific tool
just shell         # bash in the local image
just clean-image   # remove the local image
just clean-volume  # remove the throwaway test volumes
```
