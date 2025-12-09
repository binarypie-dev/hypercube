{ ... }:

{
  xdg.configFile."k9s/config.yaml".text = ''
    k9s:
      liveViewAutoRefresh: false
      refreshRate: 2
      maxConnRetry: 5
      readOnly: false
      noExitOnCtrlC: false
      ui:
        enableMouse: false
        headless: false
        logoless: false
        crumbsless: false
        reactive: false
        noIcons: false
        skin: tokyo-night
      logger:
        tail: 100
        buffer: 5000
        sinceSeconds: -1
        textWrap: false
        showTime: false
      thresholds:
        cpu:
          critical: 90
          warn: 70
        memory:
          critical: 90
          warn: 70
  '';

  xdg.configFile."k9s/skins/tokyo-night.yaml".text = ''
    k9s:
      body:
        fgColor: "#c0caf5"
        bgColor: "#1a1b26"
        logoColor: "#7aa2f7"
      prompt:
        fgColor: "#c0caf5"
        bgColor: "#1a1b26"
        suggestColor: "#7aa2f7"
      info:
        fgColor: "#bb9af7"
        sectionColor: "#7aa2f7"
      dialog:
        fgColor: "#c0caf5"
        bgColor: "#1a1b26"
        buttonFgColor: "#c0caf5"
        buttonBgColor: "#7aa2f7"
        buttonFocusFgColor: "#1a1b26"
        buttonFocusBgColor: "#9ece6a"
        labelFgColor: "#ff9e64"
        fieldFgColor: "#c0caf5"
      frame:
        border:
          fgColor: "#7aa2f7"
          focusColor: "#bb9af7"
        menu:
          fgColor: "#c0caf5"
          keyColor: "#7aa2f7"
          numKeyColor: "#ff9e64"
        crumbs:
          fgColor: "#1a1b26"
          bgColor: "#7aa2f7"
          activeColor: "#bb9af7"
        status:
          newColor: "#7aa2f7"
          modifyColor: "#bb9af7"
          addColor: "#9ece6a"
          errorColor: "#f7768e"
          highlightColor: "#ff9e64"
          killColor: "#414868"
          completedColor: "#414868"
        title:
          fgColor: "#c0caf5"
          bgColor: "#1a1b26"
          highlightColor: "#7aa2f7"
          counterColor: "#bb9af7"
          filterColor: "#9ece6a"
      views:
        charts:
          bgColor: default
          defaultDialColors:
            - "#7aa2f7"
            - "#f7768e"
          defaultChartColors:
            - "#7aa2f7"
            - "#f7768e"
        table:
          fgColor: "#c0caf5"
          bgColor: "#1a1b26"
          header:
            fgColor: "#c0caf5"
            bgColor: "#1a1b26"
            sorterColor: "#7dcfff"
        xray:
          fgColor: "#c0caf5"
          bgColor: "#1a1b26"
          cursorColor: "#7aa2f7"
          graphicColor: "#bb9af7"
          showIcons: false
        yaml:
          keyColor: "#7aa2f7"
          colonColor: "#414868"
          valueColor: "#c0caf5"
        logs:
          fgColor: "#c0caf5"
          bgColor: "#1a1b26"
          indicator:
            fgColor: "#c0caf5"
            bgColor: "#1a1b26"
  '';
}
