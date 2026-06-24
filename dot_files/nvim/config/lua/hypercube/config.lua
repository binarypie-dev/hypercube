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
  -- socket, so route yanks through the terminal escape sequence. This works
  -- locally on Ghostty and over SSH, keeping the sandbox portable.
  -- Gated on DEVCUBE so a host-native nvim keeps its own clipboard.
  --
  -- Copy is OSC 52 (write-only); paste is served from nvim's own register
  -- rather than osc52.paste(). osc52.paste() emits a clipboard *read* query
  -- (OSC 52 ; c ; ?) and blocks until the terminal answers. Ghostty on macOS
  -- doesn't reply to clipboard-read queries by default, and zellij between us
  -- and the terminal doesn't proxy the reply, so the query hangs until it
  -- times out — freezing nvim on every yank/paste/delete (LazyVim defaults to
  -- clipboard=unnamedplus, so all of them route through the + register). The
  -- terminal Stack (Terminal > Container > Multiplexer > NVIM) can't support
  -- OSC 52 read here, so we never issue the query: host->nvim paste still works
  -- via the terminal's own bracketed paste, which never touches OSC 52.
  if vim.env.DEVCUBE == "1" then
    local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok then
      local function paste()
        return { vim.fn.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
      end
      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = osc52.copy("+"),
          ["*"] = osc52.copy("*"),
        },
        paste = {
          ["+"] = paste,
          ["*"] = paste,
        },
      }
    end
  end
end

return M
