-- Hypercube Neovim Configuration
-- This config is baked into the container image at ~/.config/nvim.
-- Personal overrides live on the host at ~/.config/hypercube/nvim/lua/plugins/
-- (bind-mounted in) and are layered on top of these defaults.

-- Load hypercube config (autocmds, filetypes, clipboard, etc.)
require("hypercube.config").setup()

-- Store LazyVim state in data dir (writable, persisted in the home volume)
vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

-- Bootstrap lazy.nvim
require("config.lazy")
