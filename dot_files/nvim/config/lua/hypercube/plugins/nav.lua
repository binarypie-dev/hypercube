-- Hypercube navigation: seamless Neovim ↔ zellij movement.
--
-- Alt+hjkl moves between Neovim windows and, at the window edge, hands off to
-- the adjacent zellij pane (or tab) via `zellij action`. Pairs with
-- zellij-autolock (baked into the devcube image, see dot_files/zellij/
-- autolock.kdl), which holds zellij in Locked mode while nvim is focused so
-- these keys reach nvim instead of the multiplexer.
--
-- Ctrl+hjkl window nav is retired in lua/config/keymaps.lua so Alt+hjkl is the
-- single nav chord across the whole stack (#198).
return {
  {
    "swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<M-h>", "<cmd>ZellijNavigateLeftTab<cr>", silent = true, desc = "Focus left (nvim/zellij)" },
      { "<M-j>", "<cmd>ZellijNavigateDown<cr>", silent = true, desc = "Focus down (nvim/zellij)" },
      { "<M-k>", "<cmd>ZellijNavigateUp<cr>", silent = true, desc = "Focus up (nvim/zellij)" },
      { "<M-l>", "<cmd>ZellijNavigateRightTab<cr>", silent = true, desc = "Focus right (nvim/zellij)" },
    },
  },
}
