-- Hypercube Neovim Plugin Specs
-- This module aggregates the base Hypercube neovim configuration.
-- Users override any of these from ~/.config/hypercube/nvim/lua/plugins/.

return {
  -- Import Hypercube UI customizations
  { import = "hypercube.plugins.ui" },

  -- Import Hypercube extras (language support, etc.)
  { import = "hypercube.plugins.extras" },

  -- Import Hypercube AI (sidekick.nvim)
  { import = "hypercube.plugins.ai" },

  -- Import Hypercube workbox (smart-splits nav + :Workbox* worktree commands)
  { import = "hypercube.plugins.workbox" },
}
