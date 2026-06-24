# Proposal: Unified Keybindings Across the Hypercube Stack

> Addresses [#198](https://github.com/binarypie-dev/hypercube/issues/198) —
> "devcube: Fix keybindings mess."
>
> Status: **proposal / RFC.** No configs are changed by this document. It
> describes the target scheme, the rationale, and a staged migration.

## The problem

When you work inside `devc`, your keystrokes pass through a stack of programs,
each with its own idea of how to manage panes, tabs, and focus:

| Layer | Leader / modifier | What it grabs |
|---|---|---|
| Hyprland (host WM) | `Super` | windows, workspaces |
| Ghostty (terminal) | `Ctrl+a` leader | **tabs, splits, copy mode** |
| zellij (multiplexer) | `Ctrl+p/t/n/s/o/h/g` modes + `Alt+hjkl` | **panes, tabs, sessions** |
| workmux | (zellij tabs) | parallel-agent worktrees |
| Claude / Codex / agy | raw keys | the prompt line |
| Neovim | `Space` leader + `Ctrl+hjkl` | editor splits, everything |
| fish (vi mode), lazygit | vim keys | line editing, git |

Four concrete frictions fall out of this:

1. **Two multiplexers are stacked.** Ghostty's `Ctrl+a` (tabs/splits) *and*
   zellij both do pane/tab management. Inside `devc` you run zellij *inside*
   Ghostty, so both leaders are live and do nearly the same things. You have to
   remember which one you're "supposed" to use.
2. **Four different "move focus left" chords.** `Super+h` (Hypr), `Ctrl+a` then
   `h` (Ghostty), `Alt+h` (zellij), `Ctrl+h` (nvim). Which one works depends on
   which layer owns the boundary you're crossing. This is the keyboard dance.
3. **zellij mode soup.** Defaults give you a separate `Ctrl+<key>` per mode —
   pane, tab, resize, move, scroll, session, locked. That is precisely the
   "switching from leaders to controls to other random things" the issue calls
   out.
4. **The agent CLIs swallow keys.** `Ctrl+a` is readline / Claude Code's
   "beginning of line," and `Ctrl+hjkl` never crosses the nvim ↔ agent-pane
   boundary. So the one place you most want consistent navigation — between your
   editor and the agent running next to it — is where it breaks.

## Design principles

The fix mirrors what you've done before with a multiplexer: **wipe the default
keymaps and define a single deliberate set, entered through one leader, with one
mode instead of many.** Generalized across the whole stack, that becomes four
rules.

### 1. One layer owns multiplexing

Inside `devc`, **zellij is the only multiplexer.** Ghostty's job is to be a fast,
chrome-less renderer — nothing more. We **strip Ghostty's tab/split/copy-mode
and leader bindings entirely** so there is exactly one program managing panes and
tabs. This deletes friction #1 outright. (workmux already orchestrates *zellij*
tabs, so this also makes workmux and the multiplexer the same thing rather than a
third vocabulary.)

### 2. One modifier per layer — a 3-tier mental model that never overlaps

You should only ever reach for one of three things, and they live in different
worlds so they can never be ambiguous:

| Press | Means | Owns |
|---|---|---|
| **`Super` + …** | "talk to the OS" | Hyprland windows & workspaces |
| **`<leader>` + …** | "talk to the multiplexer" | zellij panes, tabs, sessions, agents/workmux |
| **`Space` + …** | "talk to the editor" | Neovim (LazyVim default) |

`Super` and `Space` are already correct in the current configs and keep their
vim-style `hjkl`. The work is concentrating *everything multiplexer-shaped* under
a single `<leader>` and deleting the competing vocabularies (Ghostty's `Ctrl+a`,
zellij's seven mode-chords).

### 3. Collapse zellij's modes into ONE leader mode

This is the heart of it, and it's the trick you've used before. With
`keybinds clear-defaults=true`, we throw away every default mode. Then we bind a
single `<leader>` that enters **one** custom mode. In that mode, single keys do
everything; `Esc`/`Enter` returns to Normal. No pane-mode vs tab-mode vs
resize-mode — one mode to learn, and the status bar shows its whole cheat sheet.

### 4. Seamless directional focus across the zellij ↔ nvim boundary

Moving focus is the most frequent action, so it should **not** require a leader at
all, and it should work *identically* whether the next pane is a zellij split or
an nvim window. We bind one chord — recommended **`Alt+hjkl`** — to a plugin pair
that checks "am I at the edge of nvim's splits? then tell zellij to move; else
move inside nvim." Same four keys, anywhere, no mode. This is the zellij analog of
`vim-tmux-navigator`.

Why `Alt+hjkl` and not `Ctrl+hjkl`: `Ctrl+hjkl` is claimed by readline and by the
agent TUIs (Claude/Codex), so it can't be a global nav chord. `Alt+hjkl` is
already zellij's direct-nav modifier and is free inside nvim and the agent
prompts. We reuse it everywhere and retire the rest.

## The unified scheme

### Tier 1 — Hyprland (`Super`): unchanged

Already consistent (`Super+hjkl` focus, `+Shift` move, `+Ctrl` resize, `1-0`
workspaces). It lives in its own modifier namespace and never collides with
terminal apps. No change beyond keeping it as the canonical "OS layer."

### Tier 2 — zellij (`<leader>`): one mode, custom keytable

`<leader>` enters a single mode (call it **HYPER**). Every binding below runs its
action and returns to Normal, so it reads like a leader sequence — `<leader> |`
splits right, `<leader> c` makes a tab — with no lingering mode.

| Key (after `<leader>`) | Action |
|---|---|
| `\|` | split right (vertical) |
| `-` | split down (horizontal) |
| `n` | new pane |
| `x` | close pane |
| `z` | toggle zoom/fullscreen |
| `w` | toggle floating |
| `h` `j` `k` `l` | move focus (also available bare as `Alt+hjkl`) |
| `H` `J` `K` `L` | move the pane |
| `r` | resize sub-mode (the one optional nested mode; `hjkl`/`+`/`-`, `Esc` exits) |
| `c` | new tab |
| `[` / `]` | previous / next tab |
| `1`–`9` | jump to tab _n_ (these are your workmux worktrees) |
| `,` | rename tab |
| `s` | session manager |
| `d` | detach session (leave agents running) |
| `g` | lock (pass all keys to a focused TUI); a single key unlocks |
| `q` | quit session |

Bare chords, no leader needed:

| Chord | Action |
|---|---|
| `Alt+h/j/k/l` | move focus (seamless into nvim — see Tier 3) |
| `Alt+=` / `Alt+-` | grow / shrink pane |

Sketch (`dot_files/zellij/config.kdl`):

```kdl
keybinds clear-defaults=true {
    normal {
        // single leader -> one mode
        bind "Ctrl Space" { SwitchToMode "tmux"; }   // <leader>; see "Choosing the leader"
        // seamless, no-leader focus (paired with vim-zellij-navigator)
        bind "Alt h" { MoveFocusOrTab "Left"; }
        bind "Alt l" { MoveFocusOrTab "Right"; }
        bind "Alt j" { MoveFocus "Down"; }
        bind "Alt k" { MoveFocus "Up"; }
        bind "Alt =" { Resize "Increase"; }
        bind "Alt -" { Resize "Decrease"; }
    }
    // ONE mode; every bind returns to Normal so it feels like a leader sequence
    tmux {
        bind "|" { NewPane "Right"; SwitchToMode "Normal"; }
        bind "-" { NewPane "Down";  SwitchToMode "Normal"; }
        bind "n" { NewPane;          SwitchToMode "Normal"; }
        bind "x" { CloseFocus;       SwitchToMode "Normal"; }
        bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "w" { ToggleFloatingPanes;   SwitchToMode "Normal"; }
        bind "h" { MoveFocus "Left";  SwitchToMode "Normal"; }
        bind "j" { MoveFocus "Down";  SwitchToMode "Normal"; }
        bind "k" { MoveFocus "Up";    SwitchToMode "Normal"; }
        bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
        bind "c" { NewTab;            SwitchToMode "Normal"; }
        bind "[" { GoToPreviousTab;   SwitchToMode "Normal"; }
        bind "]" { GoToNextTab;       SwitchToMode "Normal"; }
        bind "1" { GoToTab 1; SwitchToMode "Normal"; } // … 2-9
        bind "r" { SwitchToMode "resize"; }
        bind "s" { LaunchOrFocusPlugin "session-manager"; SwitchToMode "Normal"; }
        bind "d" { Detach; }
        bind "g" { SwitchToMode "locked"; }
        bind "q" { Quit; }
        bind "Esc" "Enter" { SwitchToMode "Normal"; }
    }
    locked { bind "Ctrl Space" { SwitchToMode "Normal"; } }  // single unlock
    resize { /* hjkl / +/- ; Esc -> Normal */ }
}
```

### Tier 3 — Neovim (`Space`): unchanged leader + seamless nav plugin

LazyVim's `Space` stays. The only change is to make `Alt+hjkl` cross the pane
boundary into zellij. Add **[`hiasr/vim-zellij-navigator`](https://github.com/hiasr/vim-zellij-navigator)**
(the plugin this proposal leans on) and **retire nvim's `Ctrl+hjkl` window-nav**
so there's a single nav chord everywhere:

```lua
-- dot_files/nvim/config/lua/hypercube/plugins/extras.lua (new spec)
{
  "hiasr/vim-zellij-navigator",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<A-h>", "<cmd>ZellijNavigateLeftTab<cr>",  desc = "Focus left (nvim/zellij)" },
    { "<A-j>", "<cmd>ZellijNavigateDown<cr>",     desc = "Focus down (nvim/zellij)" },
    { "<A-k>", "<cmd>ZellijNavigateUp<cr>",       desc = "Focus up (nvim/zellij)" },
    { "<A-l>", "<cmd>ZellijNavigateRightTab<cr>", desc = "Focus right (nvim/zellij)" },
  },
}
```

Pair it with a zellij keybind that only forwards `Alt+hjkl` to the pane when the
running command is nvim (the plugin documents the exact `MoveFocusOrTab` /
pass-through snippet). Net result: `Alt+h` moves left through nvim splits and then
out into the zellij pane to the left, with no mental gear-change.

(Unrelated cleanup we can fold in: nvim currently splits AI maps across
`<leader>a` (claudecode) and `<leader>A` (sidekick). Worth consolidating under one
`<leader>a` "+ai" group while we're here — minor, same Space layer, no conflict.)

### Tier 4 — the agent CLIs (Claude / Codex / agy)

These can't be rebound, so the scheme's job is to **stay out of their way**:

- Focus in/out of an agent pane uses `Alt+hjkl` — free inside every TUI.
- When an agent needs *all* the keys (e.g. its own `Ctrl+a`), `<leader> g`
  locks zellij and passes everything through; the same leader unlocks. One key,
  one concept, instead of fighting over chords.
- This is the main argument for **not** using `Ctrl+a` as the leader — see below.

### fish / lazygit

No change. They're already vim-flavored and live below the multiplexer. fish vi
mode and lazygit's `hjkl` are consistent with the rest; they don't compete for the
leader.

## Choosing the leader

One genuine decision, because it trades muscle memory against collisions:

| Option | Pro | Con |
|---|---|---|
| **`Ctrl+Space`** (recommended) | No TUI/readline claims it; clean across Claude/Codex/fish | Not the classic tmux prefix; some terminals need it allowed through |
| `Ctrl+a` | Familiar tmux/screen prefix; matches today's Ghostty | Shadows readline/Claude "start of line"; needs a double-tap to send literally |
| `Ctrl+g` | Rarely used; zellij's current lock key | Less mnemonic as a global leader |

**Recommendation: `Ctrl+Space`.** It removes the single worst conflict (the agent
prompt line) and is equally reachable. If tmux muscle memory wins, `Ctrl+a` is a
fine second choice as long as we accept the readline shadow.

## Plugins introduced

- **`hiasr/vim-zellij-navigator`** (nvim) — seamless `Alt+hjkl` focus across the
  zellij ↔ nvim boundary. The one load-bearing plugin.
- *(optional)* **`dj95/zjstatus`** (zellij) — because we strip the defaults, a
  readable status bar that shows the single HYPER-mode cheat sheet and the
  workmux tabs is worth adding so discoverability doesn't regress.

## Migration plan

1. **zellij** — rewrite `config.kdl` with `clear-defaults=true` and the
   single-mode keytable above. Highest-impact, self-contained change.
2. **Ghostty** — delete the `Ctrl+a` tab/split/copy keybinds from
   `dot_files/ghostty/config`; keep only theme/font/behavior. Ghostty becomes a
   pure renderer inside `devc`.
3. **nvim** — add `vim-zellij-navigator`, drop the `Ctrl+hjkl` window maps,
   standardize on `Alt+hjkl`. Optionally consolidate the `<leader>a` AI group.
4. **Docs** — rewrite `KEYBINDINGS.md` around the 3-tier model and the single
   HYPER keytable; refresh the cheat-sheet comment block in `config.kdl` and the
   "AI keymaps" note in `dot_files/devcube/README.md`.
5. **Validate** — `cd dot_files/devcube && just build && just test-build`, then
   `just run` and walk the table: leader → mode, `Alt+hjkl` across an
   nvim/agent boundary, workmux tab switching, lock/unlock against a live agent.

Each step is independently shippable; zellij first delivers most of the win.

## What this buys

- **One leader, one mode.** No more pane/tab/resize/scroll/session mode-chords —
  just `<leader>` then a single key, exactly the model you wanted.
- **One way to move focus** everywhere that matters: `Alt+hjkl`, including across
  the editor ↔ agent seam.
- **One multiplexer.** Ghostty stops competing with zellij.
- **A 3-tier map you can hold in your head:** `Super` = OS, `<leader>` = mux,
  `Space` = editor — three keys, three worlds, no overlap.
```
