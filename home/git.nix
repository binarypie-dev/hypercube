{ ... }:

{
  programs.git = {
    enable = true;
    userName = "binarypie";
    userEmail = "code@binarypie.com";

    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        syntax-theme = "tokyonight_night";
        side-by-side = true;
        line-numbers = true;
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictStyle = "diff3";
      diff.colorMoved = "default";
      core.editor = "nvim";
    };
  };

  # GitUI config
  xdg.configFile."gitui/key_bindings.ron".source = ./gitui/key_bindings.ron;
}
