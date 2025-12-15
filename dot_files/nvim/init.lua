-- Store lazyvim.json in data dir so config can remain read-only
-- Must be set before loading lazy.nvim
vim.g.lazyvim_json = vim.fn.stdpath("data") .. "/lazyvim.json"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
