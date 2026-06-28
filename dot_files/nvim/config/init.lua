-- Hypercube Neovim Configuration
-- Shared by two front ends, both syncing a copy into ~/.config/nvim:
--   * the host (local `nvim`): /usr/libexec/hypercube/sync-local-config on login
--   * the devcube container: its entrypoint, on every start
-- Personal overrides live at ~/.config/hypercube/nvim/lua/plugins/ (on the
-- runtimepath locally, bind-mounted in the container) and are layered on top.

-- Load hypercube config (autocmds, filetypes, clipboard, etc.)
require("hypercube.config").setup()

-- Store LazyVim state in data dir (writable, persisted in the home volume)
vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

-- Bootstrap lazy.nvim
require("config.lazy")
