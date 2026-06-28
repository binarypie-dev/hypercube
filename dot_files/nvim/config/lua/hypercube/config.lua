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

  -- Portable clipboard via OSC 52 (copy only).
  -- Inside the Hypercube container we can't reach the host Wayland/pbcopy
  -- socket, so route yanks out through the terminal escape sequence. This
  -- works locally on Ghostty and over SSH, keeping the sandbox portable.
  -- Gated on DEVCUBE so a host-native nvim keeps its own clipboard.
  --
  -- Paste is intentionally NOT wired to OSC 52. Reading the clipboard requires
  -- querying the terminal and waiting for a reply, but Ghostty (and most
  -- terminals) don't answer OSC 52 read requests, so nvim blocks until it
  -- times out. Instead, paste into nvim with terminal/OS-level paste
  -- (ctrl+shift+v), which arrives as a bracketed paste and never touches the
  -- +/* registers. The no-op paste handlers below keep those registers from
  -- triggering the blocking terminal query.
  if vim.env.DEVCUBE == "1" then
    local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok then
      local noop_paste = function()
        return { vim.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
      end
      vim.g.clipboard = {
        name = "OSC 52 (copy only)",
        copy = {
          ["+"] = osc52.copy("+"),
          ["*"] = osc52.copy("*"),
        },
        paste = {
          ["+"] = noop_paste,
          ["*"] = noop_paste,
        },
      }
    end
  end
end

return M
