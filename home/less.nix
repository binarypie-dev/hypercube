{ config, ... }:

{
  home.sessionVariables = {
    LESS = "-R --use-color -j4";
    LESSKEYIN = "${config.xdg.configHome}/less/lesskey";
  };

  xdg.configFile."less/lesskey".text = ''
    #command
    j forw-line
    k back-line
    G end
    g goto-line
    d forw-scroll
    u back-scroll
    / forw-search
    ? back-search
    n repeat-search
    N reverse-search
    q quit
  '';
}
