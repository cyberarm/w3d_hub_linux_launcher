module W3DHubLauncher
  class State < CyberarmEngine::GuiState
    include W3DHubLauncher::GuiExt

    def setup
      theme(THEME)
    end
  end
end
