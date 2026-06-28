-- Hypercube Neovim Configuration
-- Shared by two front ends:
--   * the host (local `nvim`): ~/.config/nvim/init.lua is a stub that prepends
--     this dir to the runtimepath and dofiles this file (see the skel stub in
--     build_files/hypercube/03-hypercube-configs.sh).
--   * the devcube container: the entrypoint syncs this config into ~/.config/nvim.
-- Personal overrides live at ~/.config/hypercube/nvim/lua/plugins/ (on the
-- runtimepath locally, bind-mounted in the container) and are layered on top.

-- Load hypercube config (autocmds, filetypes, clipboard, etc.)
require("hypercube.config").setup()

-- Store LazyVim state in data dir (writable, persisted in the home volume)
vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

-- Bootstrap lazy.nvim
require("config.lazy")
