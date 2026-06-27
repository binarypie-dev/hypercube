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

All entry points share one home volume, so an AI login from any of them works in
all of them.

### Parallel agents

Run `devc` (or `devc workmux`) to open the workmux workspace, then from any pane:

```bash
workmux add <branch> "<prompt>"   # new git worktree + a zellij tab running the agent
workmux list                      # show worktrees + agent status
workmux merge <branch>            # merge and clean up
workmux remove <branch>           # remove without merging
```

Each `add` opens a new zellij **tab**, so switch between agents with the
multiplexer leader: `Ctrl+Space` then `[` / `]` or `1`–`9`. zellij uses a single
leader-entered mode for everything (panes, tabs, sessions) — full keymap in
[KEYBINDINGS.md](../../KEYBINDINGS.md).

Worktrees are created on a **per-project named volume** mounted at `/worktrees`,
so they persist across restarts and stay isolated from other projects. The
volume name is derived from the launch path, so `~/Code/myrepo` always gets the
same worktrees back. (Worktrees live on the volume, not on the host — manage
them from inside `devc`, not via `git worktree` on the host.)

### Closing & resuming

`Ctrl+Space q` opens a floating prompt to leave the devcube and drop back to your
host shell:

- **Save** keeps the session. zellij serializes it to the persisted home volume,
  and the next `devc` from the same project reattaches to it — same tabs,
  worktrees, panes, cwds, and scrollback.
- **Discard** deletes the session, so the next `devc` starts fresh.
- **Cancel** stays put.

The session name is stable per project (derived from the launch path), which is
what lets `devc` find and resume the saved session.

## How it works

`scripts/devcube.sh` runs the image as an ephemeral `podman` container and mounts
only what's needed. The mounts:

| Mounted in | Purpose |
|---|---|
| named volume `hypercube-devcube-home` → `/root` | plugin/mason updates, sessions, shada, **and AI-CLI auth** — seeded from the image on first run, persisted after |
| current directory | the project you're editing |
| per-project volume `devcube-wt-<proj>-<hash>` → `/worktrees` | worktrees + workmux state (orchestrators only) |
| `~/.config/hypercube/nvim` | **your** plugin overrides, layered on top of the baked config |
| `~/.gitconfig` (ro) | commit identity |
| `$SSH_AUTH_SOCK` (Linux) | SSH agent for git/gh |

Everything else (the LazyVim config, plugins, AI CLIs, zellij/workmux/fish/
starship config) lives in the image. The container runs as `--user 0:0` so files
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
