# workbox

A [zellij](https://github.com/zellij-org/zellij) plugin that powers devcube's
parallel-agent workflow. It replaces two things that used to be bolted on:

- **workmux** — git-worktree → multiplexer orchestration. `workbox` creates a
  worktree and a zellij tab running the agent, lists them, and tears them down,
  all from inside zellij (no external process, no `WORKMUX_BACKEND` pin).
- **a seamless-nav plugin** (vim-zellij-navigator style) — `Ctrl h/j/k/l` move
  focus across zellij panes *and* nvim splits as one motion, by handing the
  keystroke to nvim (where [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)
  takes over) when nvim is focused, and moving the zellij pane otherwise.

## Layout

```
workbox/
  core/    pure Rust, no zellij-tile — pipe-message parsing + git/worktree
           string helpers + KDL layout generation. `cargo test -p workbox-core`
           runs on the host.
  plugin/  the wasm32-wasip1 cdylib that links zellij-tile and calls into core/.
           Built in the devcube Containerfile; produces workbox.wasm.
```

## How it's driven

Everything is a zellij **pipe message** — from a shell, the CLI:

```bash
zellij pipe --name workbox-add    --args branch=feat,prompt="add a logout button"
zellij pipe --name workbox-list
zellij pipe --name workbox-merge  --args branch=feat
zellij pipe --name workbox-remove --args branch=feat
```

…or from nvim via `workbox.nvim` (`:WorkboxAdd`, `:WorkboxList`, `:WorkboxMerge`,
`:WorkboxRemove`). Navigation is wired in the zellij keybindings (see
`dot_files/zellij/config.kdl`) to `MessagePlugin "workbox"` with
`name "move_focus_or_tab"`.

`add` runs `git worktree add` on the `/worktrees` volume, then opens a tab with
the agent (focused) beside nvim, both rooted in the new worktree. `merge` merges
`--no-ff`, removes the worktree, and closes the tab. State is derived on demand
from `git worktree list`; nothing extra is persisted.

## Building

Built automatically in the devcube image. To build by hand you need the wasm
target:

```bash
rustup target add wasm32-wasip1
cargo build --release --target wasm32-wasip1 -p workbox
# -> target/wasm32-wasip1/release/workbox.wasm
```

The `zellij-tile` version in `plugin/Cargo.toml` must stay aligned with the
`zellij` version installed in `dot_files/devcube/Containerfile`; bump them
together.
