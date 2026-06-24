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
  -- Copy is always OSC 52 (write-only, one-way out -- every layer forwards it).
  -- Paste is where the host OS matters:
  --
  --   Linux host: podman is native, so the OSC 52 read query (OSC 52 ; c ; ?)
  --     and its reply travel a single continuous pty to/from the terminal.
  --     The reply comes back, so osc52.paste() works -- host->nvim paste of
  --     text from other apps behaves like a normal clipboard. Keep it.
  --
  --   macOS host: podman runs the container in a Linux VM (see devcube.sh).
  --     Outbound sequences cross the VM boundary fine, but the inbound OSC 52
  --     read *reply* doesn't make it back across the host<->VM tty bridge, so
  --     osc52.paste() blocks until it times out -- freezing nvim on every
  --     yank/paste/delete (LazyVim defaults to clipboard=unnamedplus, so they
  --     all route through the + register). Serve paste from nvim's own register
  --     instead so we never issue the read query. host->nvim paste still works
  --     via the terminal's bracketed paste, which never touches OSC 52.
  --
  -- DEVCUBE_HOST_OS is the host's `uname -s`, passed in by devcube.sh, because
  -- the container is always Linux and can't otherwise tell the hosts apart.
  if vim.env.DEVCUBE == "1" then
    local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok then
      local paste
      if vim.env.DEVCUBE_HOST_OS == "Darwin" then
        local function from_register()
          return { vim.fn.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
        end
        paste = { ["+"] = from_register, ["*"] = from_register }
      else
        paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") }
      end
      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = osc52.copy("+"),
          ["*"] = osc52.copy("*"),
        },
        paste = paste,
      }
    end
  end
end

return M
