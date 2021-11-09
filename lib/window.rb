class W3DHub
  class Window < CyberarmEngine::Window
    def setup
      self.caption = "W3D Hub Launcher"

      push_state(W3DHub::States::Boot)
    end
  end
end
