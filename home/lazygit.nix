{ ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showIcons = true;
        theme = {
          lightTheme = false;
          activeBorderColor = [ "#7aa2f7" "bold" ];
          inactiveBorderColor = [ "#414868" ];
          selectedLineBgColor = [ "#1a1b26" ];
        };
      };
      keybinding = {
        universal = {
          quit = "q";
          quit-alt1 = "<c-c>";
          return = "<esc>";
          scrollUpMain = "<c-u>";
          scrollDownMain = "<c-d>";
          scrollUpMain-alt1 = "K";
          scrollDownMain-alt1 = "J";
          prevItem = "k";
          nextItem = "j";
          prevItem-alt = "<up>";
          nextItem-alt = "<down>";
          prevBlock = "h";
          nextBlock = "l";
          prevBlock-alt = "<left>";
          nextBlock-alt = "<right>";
        };
      };
    };
  };
}
