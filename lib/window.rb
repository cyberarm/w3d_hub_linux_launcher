module W3DHubLauncher
  class Window < CyberarmEngine::Window
    def setup
      self.show_cursor = true
      self.caption = format("%s | v%s (%s)", NAME, VERSION, VERSION_NAME) # "Cyberarm's W3D Hub Linux Launcher | v2.0.0 alpha"

      # push_state(States::Boot)
      push_state(States::Interface)
    end

    def needs_redraw?
      states.any?(&:needs_repaint?)
    end
  end
end
