-- Hypercube AI: sidekick.nvim
-- Runs AI coding agents in an embedded terminal and adds Copilot-powered Next
-- Edit Suggestions (NES). The agent CLIs are baked into the container image and
-- resolved via PATH.
--
-- All agents (Claude, Codex, Antigravity) are bound under `<leader>A`. `claude`
-- and `codex` are sidekick built-in presets; Antigravity is a custom CLI tool.

return {
  {
    "folke/sidekick.nvim",
    opts = {
      -- NES (Next Edit Suggestions) via the Copilot LSP. Harmlessly inert until
      -- Copilot is authenticated (`:LazyExtras` / copilot sign-in); the <Tab>
      -- mapping below falls through to a normal <Tab> when there's no suggestion.
      nes = { enabled = true },
      cli = {
        -- No terminal multiplexer by default; run agents in a plain nvim terminal.
        mux = { backend = "tmux", enabled = false },
        tools = {
          -- Antigravity (Google) is not a sidekick built-in preset, so register
          -- it as a custom CLI tool. The `agy` binary is baked into the image.
          agy = { cmd = { "agy" } },
        },
      },
    },
    keys = {
      {
        "<tab>",
        function()
          -- Jump to / apply the next edit suggestion, else fall back to <Tab>.
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Sidekick: goto/apply Next Edit Suggestion",
      },
      {
        "<leader>A",
        "",
        desc = "+ai (sidekick)",
        mode = { "n", "v" },
      },
      {
        "<leader>Aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick: toggle last CLI",
        mode = { "n", "v" },
      },
      {
        "<leader>Ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Sidekick: Claude",
        mode = { "n", "v" },
      },
      {
        "<leader>Ax",
        function()
          require("sidekick.cli").toggle({ name = "codex", focus = true })
        end,
        desc = "Sidekick: Codex",
        mode = { "n", "v" },
      },
      {
        "<leader>Ag",
        function()
          require("sidekick.cli").toggle({ name = "agy", focus = true })
        end,
        desc = "Sidekick: Antigravity",
        mode = { "n", "v" },
      },
      {
        "<leader>As",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        desc = "Sidekick: send selection",
        mode = { "v" },
      },
      {
        "<leader>Ap",
        function()
          require("sidekick.cli").prompt()
        end,
        desc = "Sidekick: ask with prompt",
        mode = { "n", "v" },
      },
    },
  },
}
