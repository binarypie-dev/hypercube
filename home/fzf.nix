{ ... }:

{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--bind=ctrl-j:down,ctrl-k:up"
      "--color=bg+:#1a1b26,bg:#1a1b26,spinner:#7aa2f7,hl:#7aa2f7"
      "--color=fg:#c0caf5,header:#7aa2f7,info:#bb9af7,pointer:#7aa2f7"
      "--color=marker:#9ece6a,fg+:#c0caf5,prompt:#bb9af7,hl+:#7aa2f7"
    ];
  };
}
