{ ... }:

{
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        vim = true;
      };
      colors = {
        table_header_color = "#7aa2f7";
        all_cpu_color = "#7aa2f7";
        avg_cpu_color = "#bb9af7";
        cpu_core_colors = [ "#7aa2f7" "#bb9af7" "#7dcfff" "#9ece6a" "#f7768e" "#ff9e64" ];
        ram_color = "#9ece6a";
        swap_color = "#ff9e64";
        rx_color = "#9ece6a";
        tx_color = "#f7768e";
        widget_title_color = "#c0caf5";
        border_color = "#414868";
        highlighted_border_color = "#7aa2f7";
        text_color = "#c0caf5";
        graph_color = "#414868";
        cursor_color = "#7aa2f7";
        selected_text_color = "#1a1b26";
        selected_bg_color = "#7aa2f7";
      };
    };
  };
}
