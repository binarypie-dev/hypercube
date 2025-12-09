{ ... }:

{
  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      show-mode-in-prompt = true;
      vi-ins-mode-string = "\\1\\e[5 q\\2";
      vi-cmd-mode-string = "\\1\\e[1 q\\2";
    };
    bindings = {
      "\\C-p" = "history-search-backward";
      "\\C-n" = "history-search-forward";
    };
  };
}
