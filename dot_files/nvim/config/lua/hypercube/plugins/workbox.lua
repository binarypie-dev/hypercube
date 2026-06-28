-- Hypercube AI: workbox integration.
--
-- Two halves of the workbox harness on the nvim side:
--
--  1. smart-splits.nvim — seamless directional movement between nvim splits and
--     zellij panes. The workbox zellij plugin binds Ctrl+h/j/k/l to
--     `move_focus_or_tab` and, when nvim is the focused pane, injects the raw
--     Ctrl+h/j/k/l byte; smart-splits catches it here and either moves an nvim
--     window or — at the edge — calls back into zellij to move the pane. No
--     extra Neovim config is needed beyond matching the keymaps below.
--
--  2. :Workbox* commands — drive worktree orchestration without leaving nvim.
--     Each shells out to `zellij pipe`, which the workbox plugin receives. This
--     is what unifies the editor with the worktree orchestrator: an agent you
--     spawn from nvim lands in the same workbox state as one spawned from a
--     shell pane.

local function zellij_pipe(name, args)
  -- Build: zellij pipe --name <name> [--args k=v,k=v]
  local cmd = { "zellij", "pipe", "--name", name }
  if args and next(args) then
    local parts = {}
    for k, v in pairs(args) do
      table.insert(parts, string.format("%s=%s", k, v))
    end
    table.insert(cmd, "--args")
    table.insert(cmd, table.concat(parts, ","))
  end
  -- Fire-and-forget; the plugin renders status in its own pane.
  vim.system(cmd, { text = true }, function(out)
    if out.code ~= 0 then
      vim.schedule(function()
        vim.notify("workbox: " .. (out.stderr or "pipe failed"), vim.log.levels.ERROR)
      end)
    end
  end)
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {
      -- At an nvim window edge, hand focus to the adjacent zellij pane (the
      -- workbox plugin forwards the keystroke here; smart-splits does the
      -- zellij-side move-focus when we're already at the edge).
      multiplexer_integration = "zellij",
    },
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split/pane" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split/pane" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to above split/pane" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split/pane" },
    },
    init = function()
      -- Worktree orchestration commands. Usage:
      --   :WorkboxAdd <branch> [prompt words...]
      --   :WorkboxMerge <branch>   :WorkboxRemove <branch>   :WorkboxList
      vim.api.nvim_create_user_command("WorkboxAdd", function(o)
        local branch = o.fargs[1]
        if not branch then
          vim.notify("usage: :WorkboxAdd <branch> [prompt...]", vim.log.levels.WARN)
          return
        end
        local args = { branch = branch }
        if #o.fargs > 1 then
          args.prompt = table.concat(vim.list_slice(o.fargs, 2, #o.fargs), " ")
        end
        zellij_pipe("workbox-add", args)
      end, { nargs = "+", desc = "workbox: new worktree + agent" })

      vim.api.nvim_create_user_command("WorkboxMerge", function(o)
        zellij_pipe("workbox-merge", { branch = o.fargs[1] })
      end, { nargs = 1, desc = "workbox: merge + tear down worktree" })

      vim.api.nvim_create_user_command("WorkboxRemove", function(o)
        zellij_pipe("workbox-remove", { branch = o.fargs[1] })
      end, { nargs = 1, desc = "workbox: remove worktree (no merge)" })

      vim.api.nvim_create_user_command("WorkboxList", function()
        zellij_pipe("workbox-list", {})
      end, { nargs = 0, desc = "workbox: refresh the worktree list" })
    end,
  },
}
