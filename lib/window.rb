class W3DHub
  class Window < CyberarmEngine::Window
    def setup
      self.caption = "W3D Hub Launcher"

      push_state(W3DHub::States::Boot)
    end

    def button_down(id)
      super

      self.borderless = !self.borderless? if id == Gosu::KB_F7
    end
  end
end
