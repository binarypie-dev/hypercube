//! workbox — the zellij plugin half.
//!
//! Thin glue between zellij's plugin API and the host-tested [`workbox_core`]
//! logic. It does three jobs, all driven by pipe messages (`zellij pipe` from a
//! shell, or `workbox.nvim` from the editor) plus zellij keybindings:
//!
//!   * worktree orchestration (the workmux replacement): `add` creates a git
//!     worktree and a tab running the agent; `merge`/`remove` tear one down;
//!     `list` renders the current set in this plugin's pane.
//!   * seamless navigation (the navigator-plugin replacement): `move_focus`
//!     hands `<C-hjkl>` to nvim when it's focused (smart-splits.nvim takes it
//!     from there) and moves the zellij pane/tab otherwise.
//!
//! All worktree mutations go through `git` via `run_command_*`; the plugin only
//! reacts to the `RunCommandResult` to open/close tabs and refresh state. The
//! parsing/string logic lives in `workbox_core` and is unit-tested on the host.

use std::collections::BTreeMap;
use std::path::PathBuf;

use workbox_core::{
    agent_tab_layout, pane_is_nvim, sanitize_branch, worktree_path, Command, Direction as Dir,
    Worktree,
};
use zellij_tile::prelude::*;

#[derive(Default)]
struct Workbox {
    /// The git repo to operate in (the project mounted by devcube). Defaults to
    /// the plugin's cwd, overridable via plugin configuration `repo_root`.
    repo_root: String,
    /// Where worktrees live (the per-project `/worktrees` volume).
    worktrees_root: String,
    /// Cached: is the currently focused pane running nvim? Drives navigation.
    focused_is_nvim: bool,
    /// Last status line + the current worktree set, both shown in `render`.
    status: String,
    worktrees: Vec<Worktree>,
}

register_plugin!(Workbox);

impl ZellijPlugin for Workbox {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.repo_root = configuration
            .get("repo_root")
            .cloned()
            .unwrap_or_else(|| ".".to_string());
        self.worktrees_root = configuration
            .get("worktrees_root")
            .cloned()
            .unwrap_or_else(|| "/worktrees".to_string());
        self.status = "workbox: requesting permissions…".to_string();

        request_permission(&[
            PermissionType::ReadApplicationState,   // pane manifest (nvim detection)
            PermissionType::ChangeApplicationState, // move focus, open/close tabs
            PermissionType::RunCommands,            // git worktree / merge
            PermissionType::OpenTerminalsOrPlugins, // agent tab
            PermissionType::WriteToStdin,           // hand <C-hjkl> to nvim
            PermissionType::ReadCliPipes,           // `zellij pipe` / workbox.nvim
        ]);
        subscribe(&[
            EventType::PermissionRequestResult,
            EventType::RunCommandResult,
            EventType::PaneUpdate,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(_) => {
                self.status = "workbox ready".to_string();
                self.refresh_worktrees();
                true
            }
            Event::PaneUpdate(manifest) => {
                let now = focused_is_nvim(&manifest);
                let changed = now != self.focused_is_nvim;
                self.focused_is_nvim = now;
                changed
            }
            Event::RunCommandResult(exit, stdout, stderr, context) => {
                self.on_command_result(exit, &stdout, &stderr, &context)
            }
            _ => false,
        }
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        match Command::parse(
            &pipe_message.name,
            pipe_message.payload.as_deref(),
            &pipe_message.args,
        ) {
            Ok(cmd) => self.dispatch(cmd),
            Err(err) => {
                self.status = format!("workbox: {err}");
                true
            }
        }
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        println!("{}", self.status);
        if self.worktrees.is_empty() {
            println!();
            println!("No agent worktrees yet. Start one:");
            println!("  :WorkboxAdd <branch> \"<prompt>\"        (from nvim)");
            println!("  zellij pipe --name workbox-add --args branch=<branch>");
        } else {
            println!();
            println!("Agent worktrees ({}):", self.worktrees.len());
            for wt in &self.worktrees {
                let name = wt.branch.as_deref().unwrap_or("(detached)");
                println!("  • {name}  —  {}", wt.path);
            }
            println!();
            println!("merge: :WorkboxMerge <branch>   remove: :WorkboxRemove <branch>");
        }
    }
}

impl Workbox {
    fn dispatch(&mut self, cmd: Command) -> bool {
        match cmd {
            Command::MoveFocus { dir, or_tab } => {
                self.navigate(dir, or_tab);
                false
            }
            // Resize passthrough is out of MVP scope: zellij's native resize mode
            // (Ctrl+n) and smart-splits' in-editor resize cover it for now.
            Command::Resize { .. } => false,
            Command::List => {
                self.refresh_worktrees();
                true
            }
            Command::Add { branch, prompt } => {
                self.add(&branch, prompt.as_deref());
                true
            }
            Command::Merge { branch } => {
                self.merge(&branch);
                true
            }
            Command::Remove { branch } => {
                self.remove(&branch, false);
                true
            }
        }
    }

    /// Seamless directional navigation. When nvim is focused we inject the raw
    /// Ctrl+hjkl byte and let smart-splits.nvim decide whether to move a window
    /// or bounce focus back to zellij; otherwise we move the zellij pane/tab.
    fn navigate(&self, dir: Dir, or_tab: bool) {
        if self.focused_is_nvim {
            write(vec![dir.ctrl_byte()]);
        } else if or_tab {
            move_focus_or_tab(to_zellij_dir(dir));
        } else {
            move_focus(to_zellij_dir(dir));
        }
    }

    fn add(&mut self, branch: &str, prompt: Option<&str>) {
        let branch = sanitize_branch(branch);
        let path = worktree_path(&self.worktrees_root, &branch);
        let mut ctx = ctx("add", &branch);
        ctx.insert("path".into(), path.clone());
        if let Some(p) = prompt {
            ctx.insert("prompt".into(), p.to_string());
        }
        self.status = format!("workbox: creating worktree '{branch}'…");
        self.git(&["worktree", "add", "-b", &branch, &path], ctx);
    }

    fn merge(&mut self, branch: &str) {
        let branch = sanitize_branch(branch);
        self.status = format!("workbox: merging '{branch}'…");
        self.git(&["merge", "--no-ff", "--no-edit", &branch], ctx("merge", &branch));
    }

    fn remove(&mut self, branch: &str, after_merge: bool) {
        let branch = sanitize_branch(branch);
        let path = worktree_path(&self.worktrees_root, &branch);
        let mut c = ctx("remove", &branch);
        if after_merge {
            c.insert("after".into(), "merge".into());
        }
        self.status = format!("workbox: removing worktree '{branch}'…");
        self.git(&["worktree", "remove", "--force", &path], c);
    }

    fn refresh_worktrees(&mut self) {
        self.git(&["worktree", "list", "--porcelain"], ctx("list", ""));
    }

    /// Run a git subcommand in the repo root, tagged with `context` so the
    /// result handler knows what it was.
    fn git(&self, args: &[&str], context: BTreeMap<String, String>) {
        let mut cmd = vec!["git"];
        cmd.extend_from_slice(args);
        run_command_with_env_variables_and_cwd(
            &cmd,
            BTreeMap::new(),
            PathBuf::from(&self.repo_root),
            context,
        );
    }

    fn on_command_result(
        &mut self,
        exit: Option<i32>,
        stdout: &[u8],
        stderr: &[u8],
        context: &BTreeMap<String, String>,
    ) -> bool {
        let action = context.get("action").map(String::as_str).unwrap_or("");
        let branch = context.get("branch").cloned().unwrap_or_default();
        let ok = exit == Some(0);
        let err = || String::from_utf8_lossy(stderr).trim().to_string();

        match action {
            "add" => {
                if ok {
                    let path = context.get("path").cloned().unwrap_or_default();
                    let prompt = context.get("prompt").map(String::as_str);
                    new_tabs_with_layout(&agent_tab_layout(&branch, &path, prompt));
                    self.status = format!("workbox: agent running in '{branch}'");
                    self.refresh_worktrees();
                } else {
                    self.status = format!("workbox: add '{branch}' failed: {}", err());
                }
            }
            "merge" => {
                if ok {
                    // Merged — tear down the worktree, which closes its tab on success.
                    self.remove(&branch, true);
                    self.status = format!("workbox: merged '{branch}', cleaning up…");
                } else {
                    self.status = format!("workbox: merge '{branch}' failed: {}", err());
                }
            }
            "remove" => {
                if ok {
                    close_worktree_tab(&branch);
                    self.status = format!("workbox: removed '{branch}'");
                    self.refresh_worktrees();
                } else {
                    self.status = format!("workbox: remove '{branch}' failed: {}", err());
                }
            }
            "list" => {
                self.worktrees =
                    workbox_core::parse_worktree_list(&String::from_utf8_lossy(stdout), &self.repo_root);
            }
            _ => return false,
        }
        true
    }
}

/// Build the per-worktree context map every git call carries.
fn ctx(action: &str, branch: &str) -> BTreeMap<String, String> {
    let mut m = BTreeMap::new();
    m.insert("action".into(), action.into());
    if !branch.is_empty() {
        m.insert("branch".into(), branch.into());
    }
    m
}

fn to_zellij_dir(dir: Dir) -> Direction {
    match dir {
        Dir::Left => Direction::Left,
        Dir::Right => Direction::Right,
        Dir::Up => Direction::Up,
        Dir::Down => Direction::Down,
    }
}

/// Find the focused pane across all tabs and decide if it's nvim.
fn focused_is_nvim(manifest: &PaneManifest) -> bool {
    manifest
        .panes
        .values()
        .flatten()
        .find(|p| p.is_focused)
        .map(|p| pane_is_nvim(&p.title, p.terminal_command.as_deref()))
        .unwrap_or(false)
}

/// Focus a worktree's tab by name and close it. Used after a worktree is
/// removed; a no-op if the tab is already gone.
fn close_worktree_tab(branch: &str) {
    go_to_tab_name(branch);
    close_focused_tab();
}
