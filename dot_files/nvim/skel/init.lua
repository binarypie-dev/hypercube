-- Hypercube Neovim Configuration
-- This is your personal nvim config. Customize by adding files to lua/plugins/

-- Add system config to runtime path (for hypercube plugin)
vim.opt.rtp:prepend("/usr/share/hypercube/config/nvim")

-- Load hypercube config (autocmds, filetypes, etc.)
require("hypercube.config").setup()

-- Store LazyVim state in data dir (writable)
vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

-- Bootstrap lazy.nvim
require("config.lazy")
