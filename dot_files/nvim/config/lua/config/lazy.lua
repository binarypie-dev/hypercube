-- Lazy.nvim Bootstrap and Configuration

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Personal overrides live at ~/.config/hypercube/nvim (a real host dir locally,
-- bind-mounted into the devcube container). Append it to the runtimepath so
-- `{ import = "plugins" }` below also picks up the user's lua/plugins/*.lua and
-- layers them on top of the baked config.
local override = vim.fn.expand("~/.config/hypercube/nvim")
if (vim.uv or vim.loop).fs_stat(override) then
  vim.opt.rtp:append(override)
end

-- Load Hypercube plugin specs (from runtimepath)
local hypercube_ui = require("hypercube.plugins.ui")
local hypercube_extras = require("hypercube.plugins.extras")
local hypercube_ai = require("hypercube.plugins.ai")

require("lazy").setup({
  spec = {
    -- LazyVim base
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Hypercube customizations (loaded via require)
    hypercube_ui,
    hypercube_extras,
    hypercube_ai,

    -- Your personal plugins (add files to ~/.config/hypercube/nvim/lua/plugins/)
    { import = "plugins" },
  },

  -- Store lockfile in data dir (writable)
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",

  defaults = {
    lazy = false,
    version = false,
  },

  install = { colorscheme = { "tokyonight", "habamax" } },

  checker = {
    enabled = true,
    notify = false,
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
