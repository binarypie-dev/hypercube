-- Hypercube keymap overrides (loaded by LazyVim after its own defaults).
--
-- Retire LazyVim's Ctrl+hjkl window navigation. Alt+hjkl (zellij-nav.nvim, see
-- lua/hypercube/plugins/nav.lua) is the single, seamless nav chord across
-- Neovim splits and zellij panes, so Ctrl+hjkl no longer needs to move windows
-- and is freed for the terminal / agents (#198).
for _, lhs in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
  pcall(vim.keymap.del, "n", lhs)
end
