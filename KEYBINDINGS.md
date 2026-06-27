# Keybindings Reference

Hypercube uses consistent vim-style keybindings across all tools. This document
provides a complete reference.

## The 3-tier model

Hypercube spans a host desktop and the `devc` container, and your keystrokes pass
through several programs at once. To avoid the "keyboard dance," keys follow one
rule: **one modifier per layer, never overlapping.** You only ever reach for one
of three things, and they live in different worlds:

| Press | Talks to | Layer |
|---|---|---|
| **`Super` + …** | the OS | Hyprland windows & workspaces |
| **`Ctrl+Space`** then a key | the multiplexer | zellij (inside `devc`): panes, tabs, sessions, agents |
| **`Space` + …** | the editor | Neovim (LazyVim) |

`Ctrl+Space` is a single **leader**: tap it to enter one mode, then press one key.
There is no pane-mode vs tab-mode vs resize-mode to juggle. See
[KEYBINDINGS-PROPOSAL.md](KEYBINDINGS-PROPOSAL.md) for the full rationale
([#198](https://github.com/binarypie-dev/hypercube/issues/198)).

> zellij owns multiplexing under the `Ctrl+Space` leader and Ghostty is a plain
> renderer (no terminal leader). Within a tab, `Alt+hjkl` moves between zellij
> panes; Neovim keeps its own `Ctrl+hjkl` for moving between its splits. The two
> are intentionally separate — Neovim is the editor layer, zellij the mux layer.

## Hyprland Window Management

The **Super** key (Windows/Command key) is the main modifier.

### Navigation

| Keybinding | Action |
|------------|--------|
| `Super + H` | Focus window left |
| `Super + J` | Focus window down |
| `Super + K` | Focus window up |
| `Super + L` | Focus window right |

### Window Movement

| Keybinding | Action |
|------------|--------|
| `Super + Shift + H` | Move window left |
| `Super + Shift + J` | Move window down |
| `Super + Shift + K` | Move window up |
| `Super + Shift + L` | Move window right |

### Window Resizing

| Keybinding | Action |
|------------|--------|
| `Super + Ctrl + H` | Resize left |
| `Super + Ctrl + J` | Resize down |
| `Super + Ctrl + K` | Resize up |
| `Super + Ctrl + L` | Resize right |

### Window Actions

| Keybinding | Action |
|------------|--------|
| `Super + C` | Close active window |
| `Super + V` | Toggle floating |
| `Super + F` | Toggle fullscreen |
| `Super + P` | Toggle pseudotile |
| `Super + S` | Toggle split direction |

### Workspaces

| Keybinding | Action |
|------------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + Shift + 1-0` | Move window to workspace 1-10 |
| `Super + Mouse Wheel` | Cycle workspaces |

### Applications

| Keybinding | Action |
|------------|--------|
| `Super + Q` | Open terminal (Ghostty) |
| `Super + E` | Open file manager |
| `Super + R` | Open app launcher (Quickshell) |
| `Super + Shift + L` | Lock screen |

### Mouse

| Keybinding | Action |
|------------|--------|
| `Super + Left Click Drag` | Move window |
| `Super + Right Click Drag` | Resize window |

---

## Ghostty Terminal

Ghostty is a plain, chrome-less renderer. **Multiplexing — tabs, splits,
panes — is owned by zellij** (see the next section), so Ghostty defines no
terminal leader of its own. Dropping the old `Ctrl+A` prefix also frees it as
readline "beginning of line" when you run `devc claude` in a plain window.

Ghostty keeps just two custom binds (plus its built-in copy/paste and
scrollback defaults):

| Keybinding | Action |
|------------|--------|
| `Ctrl+Shift+N` | New window (for local console work outside the multiplexer) |
| `Ctrl+Shift+,` | Reload config |
| `Ctrl+Shift+C` / `V` | Copy / paste (Ghostty default) |

---

## zellij (devcube multiplexer)

Inside `devc`, **zellij** is the terminal multiplexer — it manages your panes,
tabs, and sessions, and each parallel agent (workmux worktree) is a zellij tab.

The leader is **`Ctrl+Space`**. Tap it to enter **HYPER mode**, then press one
key. Every key runs its action and returns to Normal, so it reads like a leader
sequence — `Ctrl+Space |` splits, `Ctrl+Space c` makes a tab. There is only one
mode to learn. `Esc` / `Enter` leaves HYPER mode.

### Panes

| Keybinding | Action |
|------------|--------|
| `Ctrl+Space` `\|` | Split right (vertical) |
| `Ctrl+Space` `-` | Split down (horizontal) |
| `Ctrl+Space` `n` | New pane |
| `Ctrl+Space` `x` | Close pane |
| `Ctrl+Space` `z` | Toggle zoom/fullscreen |
| `Ctrl+Space` `w` | Toggle floating panes |
| `Ctrl+Space` `e` | Embed / float pane |
| `Ctrl+Space` `h/j/k/l` | Move focus |
| `Ctrl+Space` `H/J/K/L` | Move the pane |

### Tabs (workmux worktrees)

| Keybinding | Action |
|------------|--------|
| `Ctrl+Space` `c` | New tab |
| `Ctrl+Space` `[` / `]` | Previous / next tab |
| `Ctrl+Space` `1`–`9` | Jump to tab _n_ |
| `Ctrl+Space` `,` | Rename tab |

### Resize, session, lock

| Keybinding | Action |
|------------|--------|
| `Ctrl+Space` `r` | Resize sub-mode (then `h/j/k/l` or `+`/`-`; `Esc` exits) |
| `Ctrl+Space` `s` | Session manager |
| `Ctrl+Space` `d` | Detach session (leave agents running) |
| `Ctrl+Space` `q` | Quit — floating prompt: **Save** (resume on next `devc`), **Discard**, or **Cancel** |
| `Ctrl+Space` `g` | Lock — pass every key to a focused TUI; `Ctrl+Space` again unlocks |

### No leader needed

These work everywhere, no mode required:

| Keybinding | Action |
|------------|--------|
| `Alt + h/j/k/l` | Move focus (hops between tabs at the edges) |
| `Alt + =` / `Alt + -` | Grow / shrink pane |

> `Alt+hjkl` moves between zellij **panes**. Inside Neovim, use Neovim's own
> `Ctrl+hjkl` to move between **its** splits (see the Neovim section); the two
> navigation layers are kept separate by design.

---

## workmux (parallel agents)

[workmux](https://github.com/raine/workmux) orchestrates parallel agents on top of
zellij: each `workmux add` creates a git worktree and opens it as **its own zellij
tab** running the agent. So workmux has no separate keybindings — you navigate its
worktrees with the zellij tab keys above (`Ctrl+Space [` / `]` or `Ctrl+Space 1-9`).

| Command (run in any pane) | Action |
|---|---|
| `workmux add <branch> "<prompt>"` | New worktree + zellij tab running the agent |
| `workmux list` | Show worktrees + agent status |
| `workmux merge <branch>` | Merge and clean up |
| `workmux remove <branch>` | Remove without merging |
| `workmux dashboard` | Live control center (the default `devc` layout) |

---

## Fish Shell (Vi Mode)

Fish shell is configured with vi mode. Press `Escape` to enter normal mode.

### Mode Switching

| Key | Action |
|-----|--------|
| `Escape` | Enter normal mode |
| `i` | Insert mode (before cursor) |
| `a` | Insert mode (after cursor) |
| `I` | Insert at line start |
| `A` | Insert at line end |

### Normal Mode Navigation

| Key | Action |
|-----|--------|
| `h` | Move left |
| `l` | Move right |
| `w` | Next word |
| `b` | Previous word |
| `0` | Line start |
| `$` | Line end |
| `^` | First non-blank |

### Normal Mode Editing

| Key | Action |
|-----|--------|
| `x` | Delete character |
| `dw` | Delete word |
| `dd` | Delete line |
| `D` | Delete to end of line |
| `cw` | Change word |
| `cc` | Change line |
| `C` | Change to end of line |
| `u` | Undo |
| `p` | Paste after |
| `P` | Paste before |

### History

| Key | Action |
|-----|--------|
| `k` or `Ctrl+P` | Previous command |
| `j` or `Ctrl+N` | Next command |
| `/` | Search history backward |
| `?` | Search history forward |

---

## Neovim (LazyVim)

Neovim uses LazyVim with **Space** as the leader key.

### Essential Commands

| Keybinding | Action |
|------------|--------|
| `Space` | Show command menu (which-key) |
| `Space Space` | Find files |
| `Space /` | Search in project |
| `Space e` | File explorer |
| `Space gg` | Lazygit |

### File Navigation

| Keybinding | Action |
|------------|--------|
| `Space ff` | Find files |
| `Space fr` | Recent files |
| `Space fb` | Buffers |
| `Space fg` | Live grep |

### Windows

| Keybinding | Action |
|------------|--------|
| `Ctrl+H/J/K/L` | Navigate Neovim windows |
| `Space w` | Window menu |
| `Space -` | Horizontal split |
| `Space \|` | Vertical split |

> `Ctrl+hjkl` moves between Neovim's own splits; `Alt+hjkl` moves between zellij
> panes (see the zellij section). They're separate layers by design.

### Buffers

| Keybinding | Action |
|------------|--------|
| `Space bd` | Delete buffer |
| `Space bb` | Switch buffer |
| `H` / `L` | Previous/Next buffer |

### Code

| Keybinding | Action |
|------------|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover documentation |
| `Space ca` | Code actions |
| `Space cr` | Rename symbol |
| `Space cf` | Format |

### Git

| Keybinding | Action |
|------------|--------|
| `Space gg` | Lazygit |
| `Space gf` | Git files |
| `Space gc` | Git commits |
| `]h` / `[h` | Next/prev hunk |

For complete LazyVim documentation, see [lazyvim.org](https://www.lazyvim.org/).

---

## Lazygit

Lazygit uses vim-style navigation by default.

### Navigation

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate panels/items |
| `H/L` | Scroll left/right diff |
| `[/]` | Previous/next panel |
| `?` | Show keybindings |

### Common Actions

| Key | Action |
|-----|--------|
| `Space` | Stage/unstage file |
| `a` | Stage all |
| `c` | Commit |
| `P` | Push |
| `p` | Pull |
| `Enter` | View file/expand |
| `q` | Quit |

---

## Multimedia Keys

System-wide media controls work regardless of focused application:

| Key | Action |
|-----|--------|
| `Volume Up/Down` | Adjust volume (with OSD) |
| `Volume Mute` | Toggle mute |
| `Brightness Up/Down` | Adjust brightness (with OSD) |
| `Play/Pause` | Toggle media playback |
| `Next/Previous` | Skip track |
