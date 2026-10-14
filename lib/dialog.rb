module W3DHubLauncher
  class Dialog < CyberarmEngine::Dialog
    include GuiExt

    def setup
      theme(THEME)

      background TRANSLUCENT_GRAY
    end
  end
end
