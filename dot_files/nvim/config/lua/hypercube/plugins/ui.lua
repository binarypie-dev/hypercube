-- Hypercube UI Customizations
-- Dashboard, statuscolumn, picker settings

return {
  -- Snacks.nvim customizations
  {
    "folke/snacks.nvim",
    opts = {
      statuscolumn = {
        enabled = true,
      },
      picker = {
        files = {
          sources = {
            exclude = { "build/**", "target/**", ".git", ".dart_tool" },
            hidden = true,
            ignored = true,
          },
          grep = {
            exclude = { "build/**", "target/**", ".git", ".dart_tool" },
            hidden = true,
            ignored = true,
          },
          explorer = {
            exclude = { "build/**", "target/**", ".git", ".dart_tool" },
            hidden = true,
            ignored = true,
          },
        },
      },
      dashboard = {
        preset = {
          header = [[

 ██╗   ██╗ ██╗ ███╗   ███╗
 ██║   ██║ ██║ ████╗ ████║
 ██║   ██║ ██║ ██╔████╔██║
 ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
  ╚████╔╝  ██║ ██║ ╚═╝ ██║
   ╚═══╝   ╚═╝ ╚═╝     ╚═╝
          ]],
        },
      },
    },
  },
}
