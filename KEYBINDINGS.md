# Keybindings Reference

Hypercube uses consistent vim-style keybindings across all tools. This document provides a complete reference.

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

Ghostty uses **Ctrl+A** as the leader key (similar to tmux/screen).

### Tabs

| Keybinding | Action |
|------------|--------|
| `Ctrl+A, C` | New tab |
| `Ctrl+A, N` | Next tab |
| `Ctrl+A, P` | Previous tab |
| `Ctrl+A, W` | Tab overview |

### Panes (Splits)

| Keybinding | Action |
|------------|--------|
| `Ctrl+A, Shift+\` | Vertical split |
| `Ctrl+A, -` | Horizontal split |
| `Ctrl+A, X` | Close pane |
| `Ctrl+A, Z` | Zoom/unzoom pane |
| `Alt+F` | Toggle fullscreen pane |

### Pane Navigation (Vim-style)

| Keybinding | Action |
|------------|--------|
| `Ctrl+A, H` | Focus pane left |
| `Ctrl+A, J` | Focus pane down |
| `Ctrl+A, K` | Focus pane up |
| `Ctrl+A, L` | Focus pane right |

### Pane Resizing

| Keybinding | Action |
|------------|--------|
| `Ctrl+A, R` | Enter resize mode |
| Then `H/J/K/L` | Resize in direction |

### Other

| Keybinding | Action |
|------------|--------|
| `Ctrl+A, [` | Enter copy mode (vim navigation) |
| `Ctrl+A, Shift+R` | Reload config |

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
| `Ctrl+H/J/K/L` | Navigate windows |
| `Space w` | Window menu |
| `Space -` | Horizontal split |
| `Space \|` | Vertical split |

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
