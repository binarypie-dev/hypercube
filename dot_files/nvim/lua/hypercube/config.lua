-- Hypercube Neovim Configuration
-- Autocmds, options, and other settings

local M = {}

function M.setup()
  -- Custom filetypes
  vim.filetype.add({
    pattern = {
      [".*%.env.*"] = "dotenv",
    },
  })
end

return M
