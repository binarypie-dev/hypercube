{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil # Nix LSP
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      gopls
      rust-analyzer
      pyright
      terraform-ls
      yaml-language-server

      # Formatters
      stylua
      nixfmt-classic
      nodePackages.prettier
      black
      shfmt

      # Tools
      ripgrep
      fd
      tree-sitter
      gcc # For tree-sitter compilation
    ];
  };

  # LazyVim configuration (managed outside Nix for flexibility)
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
