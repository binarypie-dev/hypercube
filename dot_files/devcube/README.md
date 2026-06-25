# devcube — containerized IDE + parallel-agent orchestration

A self-contained, **portable** development environment baked into one podman
image: [LazyVim](https://github.com/LazyVim/LazyVim), the full dev toolchain
(LSPs/formatters/linters), the AI coding agents, **and**
[zellij](https://github.com/zellij-org/zellij) +
[workmux](https://github.com/raine/workmux) for running multiple agents in
parallel — each in its own git worktree, all inside a single container (no
nested podman).

A single wrapper installed as `devc` runs it. Runs identically on the Hypercube
Linux desktop, a remote box, and macOS — no distrobox required.

## What's baked in

- **Editor:** Neovim + LazyVim with Hypercube customizations.
- **AI agents:** Claude Code (`claude`), OpenAI Codex (`codex`), Antigravity
  (`agy`), GitHub CLI (`gh`). Wired into nvim via `claudecode.nvim` and
  `sidekick.nvim`.
- **Parallel agents:** zellij (terminal multiplexer) + workmux (git-worktree →
  multiplexer orchestration).
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
| `devc`            | the workmux parallel-agent workspace (a zellij session) — the default |
| `devc zellij`     | a plain zellij multiplexer session |
| `devc nvim [file]`| the editor |
| `devc claude`     | Claude Code CLI, run directly |
| `devc codex`      | OpenAI Codex CLI, run directly |
| `devc agy`        | Antigravity CLI, run directly |
| `devc session …`  | manage running sessions (see below) |

All entry points share one home volume, so an AI login from any of them works in
all of them.

### Managing sessions

Only one session (`devc` / `devc workmux` / `devc zellij`) runs per project at a
time — a second on the same folder would share its `/worktrees` volume + workmux
state and corrupt it, so it's refused. `devc session` inspects and manages them
from the host:

| Command | What it does |
|---|---|
| `devc session list`              | list running devcube sessions (project, tool, status) |
| `devc session stop [<path>\|all]` | stop a running session — defaults to the current project |
| `devc session remove [<path>]`   | remove a project's worktree/state volume (the per-project state that gets corrupted); refuses while a session is running |

Single-tool sessions (`devc nvim` / `devc claude` / …) mount no shared state and
stay fully concurrent.

### Parallel agents

Run `devc` (or `devc workmux`) to open the workmux workspace, then from any pane:

```bash
workmux add <branch> "<prompt>"   # new git worktree + a zellij tab running the agent
workmux list                      # show worktrees + agent status
workmux merge <branch>            # merge and clean up
workmux remove <branch>           # remove without merging
```

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
| per-project volume `devcube-wt-<proj>-<hash>` → `/worktrees` | worktrees + workmux state (sessions only) |
| `~/.config/hypercube/nvim` | **your** plugin overrides, layered on top of the baked config |
| `~/.gitconfig` (ro) | commit identity |
| `$SSH_AUTH_SOCK` (Linux) | SSH agent for git/gh |

Everything else (the LazyVim config, plugins, AI CLIs, zellij/workmux/fish/
starship config) lives in the image. The container runs as `--user 0:0` so files
you edit are owned by your host user under rootless podman. Multiple sessions run
concurrently — except that only **one session** (`devc` / `devc workmux` /
`devc zellij`) may run per project at a time, since they share that project's
`/worktrees` volume + workmux state; a second one refuses with a message rather
than racing into the shared state and corrupting it (manage them with
`devc session`). Single-tool sessions (`devc nvim` / `devc claude` / ...) mount no
shared state and stay concurrent.

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
workmux/nvim configs can be baked), which the recipes handle for you:

```bash
cd dot_files/devcube

just build         # build localhost/devcube
just test-build    # verify nvim + toolchain + AI CLIs + zellij/workmux/fish/starship run
just run           # launch the workmux workspace from the local image (throwaway volumes)
just run nvim .    # ...or a specific tool
just shell         # bash in the local image
just clean-image   # remove the local image
just clean-volume  # remove the throwaway test volumes
```
