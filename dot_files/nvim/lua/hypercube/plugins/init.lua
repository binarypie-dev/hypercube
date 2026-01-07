-- Hypercube Neovim Plugin Specs
-- This module provides the base Hypercube neovim configuration
-- Users can override any of these in their own lua/plugins/ directory

return {
  -- Import Hypercube UI customizations
  { import = "hypercube.plugins.ui" },

  -- Import Hypercube extras (language support, etc.)
  { import = "hypercube.plugins.extras" },
}
