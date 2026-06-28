//! Pure, host-testable core for the `workbox` zellij plugin.
//!
//! Everything here is plain Rust with no `zellij-tile` dependency, so it builds
//! and unit-tests on the host (`cargo test -p workbox-core`). The wasm `plugin`
//! crate calls into this for: parsing the pipe messages that drive workbox,
//! turning a free-form handle into a safe git branch + worktree directory, and
//! mapping a navigation direction onto the keystroke nvim expects.
//!
//! Pipe messages reach the plugin in two shapes, both handled by
//! [`Command::parse`]:
//!   * worktree control — `name="workbox-<verb>"`, data in `args`/`payload`
//!     (sent by `workbox.nvim` and the `zellij pipe` CLI), and
//!   * navigation — `name="move_focus"|"move_focus_or_tab"|"resize"`,
//!     direction in `payload` (the vim-zellij-navigator keybinding convention,
//!     so its KDL examples and any existing muscle memory carry over).

use std::collections::BTreeMap;

/// A cardinal direction for pane focus / resize.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Direction {
    Left,
    Right,
    Up,
    Down,
}

impl Direction {
    /// Accept both full words (`left`) and vim letters (`h`), case-insensitively.
    pub fn parse(s: &str) -> Option<Direction> {
        match s.trim().to_ascii_lowercase().as_str() {
            "left" | "h" => Some(Direction::Left),
            "down" | "j" => Some(Direction::Down),
            "up" | "k" => Some(Direction::Up),
            "right" | "l" => Some(Direction::Right),
            _ => None,
        }
    }

    /// The vim motion letter for this direction.
    pub fn vim_letter(self) -> char {
        match self {
            Direction::Left => 'h',
            Direction::Down => 'j',
            Direction::Up => 'k',
            Direction::Right => 'l',
        }
    }

    /// The raw control byte (Ctrl+letter) to inject into a focused nvim pane so
    /// that `<C-h/j/k/l>` window motions fire. Ctrl masks the letter to bits
    /// 1-26: Ctrl+h=0x08, Ctrl+j=0x0a, Ctrl+k=0x0b, Ctrl+l=0x0c.
    pub fn ctrl_byte(self) -> u8 {
        (self.vim_letter() as u8) & 0x1f
    }
}

/// A parsed instruction for the plugin.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Command {
    /// Create a worktree + a tab running the agent (optionally seeded with a prompt).
    Add {
        branch: String,
        prompt: Option<String>,
    },
    /// Merge the branch back, remove its worktree, close its tab.
    Merge { branch: String },
    /// Remove the worktree + close its tab without merging.
    Remove { branch: String },
    /// Re-render the worktree list in the plugin pane.
    List,
    /// Move focus; `or_tab` cycles tabs when already at the edge.
    MoveFocus { dir: Direction, or_tab: bool },
    /// Resize the focused pane in a direction.
    Resize { dir: Direction },
}

/// Why a pipe message could not be turned into a [`Command`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
    UnknownCommand(String),
    MissingBranch(String),
    MissingDirection(String),
    BadDirection(String),
}

impl std::fmt::Display for ParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ParseError::UnknownCommand(n) => write!(f, "unknown workbox command: {n}"),
            ParseError::MissingBranch(n) => write!(f, "{n} requires a branch (args.branch or payload)"),
            ParseError::MissingDirection(n) => write!(f, "{n} requires a direction (payload)"),
            ParseError::BadDirection(d) => write!(f, "not a direction: {d}"),
        }
    }
}

impl Command {
    /// Parse a pipe message into a [`Command`].
    ///
    /// `name` is the pipe name, `payload` its free-form body (used for the
    /// branch/prompt/direction when no structured arg is given), and `args` the
    /// key/value pairs. A `workbox-` prefix on `name` is optional and stripped.
    pub fn parse(
        name: &str,
        payload: Option<&str>,
        args: &BTreeMap<String, String>,
    ) -> Result<Command, ParseError> {
        let verb = name.trim().trim_start_matches("workbox-");
        let payload = payload.map(str::trim).filter(|s| !s.is_empty());
        let arg = |k: &str| args.get(k).map(|s| s.trim()).filter(|s| !s.is_empty());

        match verb {
            "add" | "new" => {
                let branch = arg("branch")
                    .or(payload)
                    .ok_or_else(|| ParseError::MissingBranch(verb.to_string()))?;
                let prompt = arg("prompt").map(str::to_string);
                Ok(Command::Add {
                    branch: branch.to_string(),
                    prompt,
                })
            }
            "merge" => Ok(Command::Merge {
                branch: branch_of(verb, payload, &arg)?,
            }),
            "remove" | "rm" => Ok(Command::Remove {
                branch: branch_of(verb, payload, &arg)?,
            }),
            "list" | "ls" => Ok(Command::List),
            "move_focus" | "move_focus_or_tab" => {
                let raw = payload
                    .or(arg("direction"))
                    .ok_or_else(|| ParseError::MissingDirection(verb.to_string()))?;
                let dir = Direction::parse(raw).ok_or_else(|| ParseError::BadDirection(raw.to_string()))?;
                Ok(Command::MoveFocus {
                    dir,
                    or_tab: verb == "move_focus_or_tab",
                })
            }
            "resize" => {
                let raw = payload
                    .or(arg("direction"))
                    .ok_or_else(|| ParseError::MissingDirection(verb.to_string()))?;
                let dir = Direction::parse(raw).ok_or_else(|| ParseError::BadDirection(raw.to_string()))?;
                Ok(Command::Resize { dir })
            }
            other => Err(ParseError::UnknownCommand(other.to_string())),
        }
    }
}

fn branch_of<'a>(
    verb: &str,
    payload: Option<&'a str>,
    arg: &dyn Fn(&str) -> Option<&'a str>,
) -> Result<String, ParseError> {
    arg("branch")
        .or(payload)
        .map(str::to_string)
        .ok_or_else(|| ParseError::MissingBranch(verb.to_string()))
}

/// Turn a free-form handle into a safe git branch name: lowercase, runs of
/// disallowed characters collapse to a single `-`, slashes are preserved (git
/// allows `feature/foo`), and leading/trailing separators are trimmed. Empty or
/// all-invalid input yields `"work"` so we never produce an invalid ref.
pub fn sanitize_branch(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let mut prev_sep = true; // true => suppress a leading separator
    for ch in input.trim().to_ascii_lowercase().chars() {
        let keep = ch.is_ascii_alphanumeric() || matches!(ch, '.' | '_' | '/');
        if keep {
            out.push(ch);
            prev_sep = false;
        } else if !prev_sep {
            out.push('-');
            prev_sep = true;
        }
    }
    let trimmed = out.trim_matches(|c| c == '-' || c == '/' || c == '.');
    if trimmed.is_empty() {
        "work".to_string()
    } else {
        trimmed.to_string()
    }
}

/// The on-disk worktree directory for a branch under `worktrees_root`. The
/// branch slug flattens `/` to `-` so a nested branch (`feature/foo`) maps to a
/// single directory (`/worktrees/feature-foo`).
pub fn worktree_path(worktrees_root: &str, branch: &str) -> String {
    let slug = sanitize_branch(branch).replace('/', "-");
    format!("{}/{}", worktrees_root.trim_end_matches('/'), slug)
}

/// A worktree as parsed from `git worktree list --porcelain`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Worktree {
    pub path: String,
    /// Short branch name (`refs/heads/` stripped), or `None` when detached.
    pub branch: Option<String>,
}

/// Parse `git worktree list --porcelain` into just the agent worktrees. Records
/// are separated by blank lines; each starts with `worktree <path>` and may
/// carry a `branch refs/heads/<name>` line. The main checkout — which git always
/// lists first — is dropped, as is any record whose path equals `main_root`
/// (belt-and-suspenders, since `main_root` may be relative like ".").
pub fn parse_worktree_list(porcelain: &str, main_root: &str) -> Vec<Worktree> {
    let main = main_root.trim_end_matches('/');
    let mut all: Vec<Worktree> = Vec::new();
    let mut path: Option<String> = None;
    let mut branch: Option<String> = None;

    let flush = |path: &mut Option<String>, branch: &mut Option<String>, out: &mut Vec<Worktree>| {
        if let Some(p) = path.take() {
            out.push(Worktree { path: p, branch: branch.take() });
        }
        *branch = None;
    };

    for line in porcelain.lines() {
        if let Some(p) = line.strip_prefix("worktree ") {
            flush(&mut path, &mut branch, &mut all);
            path = Some(p.trim().to_string());
        } else if let Some(b) = line.strip_prefix("branch ") {
            branch = Some(b.trim().trim_start_matches("refs/heads/").to_string());
        }
    }
    flush(&mut path, &mut branch, &mut all);

    if !all.is_empty() {
        all.remove(0); // the main worktree is always listed first
    }
    all.retain(|w| w.path.trim_end_matches('/') != main);
    all
}

/// Escape a string for a KDL double-quoted value.
pub fn kdl_escape(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}

/// A zellij layout (KDL) for one worktree: the agent (focused) beside nvim, both
/// rooted in the worktree dir — mirroring the old workmux per-window panes. When
/// a `prompt` is given it is passed to the agent as its initial positional arg.
pub fn agent_tab_layout(branch: &str, cwd: &str, prompt: Option<&str>) -> String {
    let name = kdl_escape(branch);
    let cwd = kdl_escape(cwd);
    let agent = match prompt {
        Some(p) if !p.trim().is_empty() => format!(
            "pane command=\"claude\" cwd=\"{cwd}\" focus=true {{\n            args \"{}\"\n        }}",
            kdl_escape(p)
        ),
        _ => format!("pane command=\"claude\" cwd=\"{cwd}\" focus=true"),
    };
    format!(
        "layout {{\n    tab name=\"{name}\" focus=true {{\n        {agent}\n        pane command=\"nvim\" cwd=\"{cwd}\"\n    }}\n}}\n"
    )
}

/// Whether a pane is running nvim, inferred from its title or launch command.
/// Used so navigation hands `<C-hjkl>` to nvim instead of moving the zellij
/// pane when the focused pane is the editor.
pub fn pane_is_nvim(title: &str, command: Option<&str>) -> bool {
    let hay = |s: &str| {
        let s = s.to_ascii_lowercase();
        s == "nvim" || s == "vim" || s.contains("nvim") || s.contains("vim ")
    };
    command.map(hay).unwrap_or(false) || hay(title)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(pairs: &[(&str, &str)]) -> BTreeMap<String, String> {
        pairs.iter().map(|(k, v)| (k.to_string(), v.to_string())).collect()
    }

    #[test]
    fn direction_parses_words_and_letters() {
        assert_eq!(Direction::parse("Left"), Some(Direction::Left));
        assert_eq!(Direction::parse("h"), Some(Direction::Left));
        assert_eq!(Direction::parse(" J "), Some(Direction::Down));
        assert_eq!(Direction::parse("nope"), None);
    }

    #[test]
    fn ctrl_bytes_match_control_chars() {
        assert_eq!(Direction::Left.ctrl_byte(), 0x08);
        assert_eq!(Direction::Down.ctrl_byte(), 0x0a);
        assert_eq!(Direction::Up.ctrl_byte(), 0x0b);
        assert_eq!(Direction::Right.ctrl_byte(), 0x0c);
    }

    #[test]
    fn add_takes_branch_from_args_or_payload() {
        let c = Command::parse("workbox-add", None, &args(&[("branch", "feat"), ("prompt", "do it")])).unwrap();
        assert_eq!(c, Command::Add { branch: "feat".into(), prompt: Some("do it".into()) });

        let c = Command::parse("add", Some("feat"), &BTreeMap::new()).unwrap();
        assert_eq!(c, Command::Add { branch: "feat".into(), prompt: None });
    }

    #[test]
    fn add_without_branch_errors() {
        let e = Command::parse("workbox-add", None, &BTreeMap::new()).unwrap_err();
        assert_eq!(e, ParseError::MissingBranch("add".into()));
    }

    #[test]
    fn merge_remove_list_parse() {
        assert_eq!(
            Command::parse("workbox-merge", Some("feat"), &BTreeMap::new()).unwrap(),
            Command::Merge { branch: "feat".into() }
        );
        assert_eq!(
            Command::parse("rm", None, &args(&[("branch", "feat")])).unwrap(),
            Command::Remove { branch: "feat".into() }
        );
        assert_eq!(Command::parse("list", None, &BTreeMap::new()).unwrap(), Command::List);
    }

    #[test]
    fn nav_commands_parse_with_or_tab_flag() {
        assert_eq!(
            Command::parse("move_focus_or_tab", Some("left"), &BTreeMap::new()).unwrap(),
            Command::MoveFocus { dir: Direction::Left, or_tab: true }
        );
        assert_eq!(
            Command::parse("move_focus", Some("k"), &BTreeMap::new()).unwrap(),
            Command::MoveFocus { dir: Direction::Up, or_tab: false }
        );
        assert_eq!(
            Command::parse("resize", Some("j"), &BTreeMap::new()).unwrap(),
            Command::Resize { dir: Direction::Down }
        );
    }

    #[test]
    fn nav_without_direction_errors() {
        assert_eq!(
            Command::parse("move_focus", None, &BTreeMap::new()).unwrap_err(),
            ParseError::MissingDirection("move_focus".into())
        );
        assert_eq!(
            Command::parse("resize", Some("sideways"), &BTreeMap::new()).unwrap_err(),
            ParseError::BadDirection("sideways".into())
        );
    }

    #[test]
    fn unknown_command_errors() {
        assert_eq!(
            Command::parse("workbox-frobnicate", None, &BTreeMap::new()).unwrap_err(),
            ParseError::UnknownCommand("frobnicate".into())
        );
    }

    #[test]
    fn branch_sanitization() {
        assert_eq!(sanitize_branch("Fix the Bug!"), "fix-the-bug");
        assert_eq!(sanitize_branch("  feature/Foo Bar  "), "feature/foo-bar");
        assert_eq!(sanitize_branch("---weird---"), "weird");
        assert_eq!(sanitize_branch("!!!"), "work");
        assert_eq!(sanitize_branch("keep_under.score"), "keep_under.score");
    }

    #[test]
    fn worktree_paths_flatten_slashes() {
        assert_eq!(worktree_path("/worktrees", "feature/foo"), "/worktrees/feature-foo");
        assert_eq!(worktree_path("/worktrees/", "Bar Baz"), "/worktrees/bar-baz");
    }

    #[test]
    fn worktree_list_parsing() {
        let porcelain = "\
worktree /home/user/proj
HEAD 1111111111111111111111111111111111111111
branch refs/heads/main

worktree /worktrees/feat
HEAD 2222222222222222222222222222222222222222
branch refs/heads/feat

worktree /worktrees/detached
HEAD 3333333333333333333333333333333333333333
detached
";
        // Even with a relative main_root ("."), the first record (the main
        // checkout) is dropped, so the absolute main path never leaks in.
        let wts = parse_worktree_list(porcelain, ".");
        assert_eq!(wts.len(), 2);
        assert_eq!(wts[0], Worktree { path: "/worktrees/feat".into(), branch: Some("feat".into()) });
        assert_eq!(wts[1], Worktree { path: "/worktrees/detached".into(), branch: None });

        // And an explicit absolute main_root match is also fine.
        assert_eq!(parse_worktree_list(porcelain, "/home/user/proj").len(), 2);
    }

    #[test]
    fn kdl_escaping() {
        assert_eq!(kdl_escape(r#"say "hi""#), r#"say \"hi\""#);
        assert_eq!(kdl_escape(r"a\b"), r"a\\b");
    }

    #[test]
    fn agent_layout_with_and_without_prompt() {
        let with = agent_tab_layout("feat", "/worktrees/feat", Some(r#"fix "it""#));
        assert!(with.contains("tab name=\"feat\" focus=true"));
        assert!(with.contains("pane command=\"claude\" cwd=\"/worktrees/feat\" focus=true"));
        assert!(with.contains(r#"args "fix \"it\"""#));
        assert!(with.contains("pane command=\"nvim\" cwd=\"/worktrees/feat\""));
        assert!(with.starts_with("layout {"));

        let without = agent_tab_layout("feat", "/worktrees/feat", None);
        assert!(!without.contains("args "));
        assert!(without.contains("pane command=\"claude\" cwd=\"/worktrees/feat\" focus=true"));
    }

    #[test]
    fn nvim_detection() {
        assert!(pane_is_nvim("nvim", None));
        assert!(pane_is_nvim("editor", Some("nvim")));
        assert!(pane_is_nvim("nvim src/lib.rs", None));
        assert!(!pane_is_nvim("claude", Some("claude")));
        assert!(!pane_is_nvim("fish", None));
    }
}
