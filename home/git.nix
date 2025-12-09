{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "binarypie";
        email = "code@binarypie.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictStyle = "diff3";
      diff.colorMoved = "default";
      core.editor = "nvim";
    };
  };

  # Delta for better diffs
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      syntax-theme = "tokyonight_night";
      side-by-side = true;
      line-numbers = true;
    };
  };

  # GitUI config
  xdg.configFile."gitui/key_bindings.ron".source = ./gitui/key_bindings.ron;
}
