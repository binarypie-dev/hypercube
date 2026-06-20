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

  -- Portable clipboard via OSC 52.
  -- Inside the Hypercube container we can't reach the host Wayland/pbcopy
  -- socket, so route yanks/pastes through the terminal escape sequence. This
  -- works locally on Ghostty and over SSH, keeping the sandbox portable.
  -- Gated on HYPERCUBE_NVIM so a host-native nvim keeps its own clipboard.
  if vim.env.HYPERCUBE_NVIM == "1" then
    local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok then
      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = osc52.copy("+"),
          ["*"] = osc52.copy("*"),
        },
        paste = {
          ["+"] = osc52.paste("+"),
          ["*"] = osc52.paste("*"),
        },
      }
    end
  end
end

return M
