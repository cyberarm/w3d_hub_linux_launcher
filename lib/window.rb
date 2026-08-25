module W3DHubLauncher
  class Window < CyberarmEngine::Window
    def setup
      self.show_cursor = true
      self.caption = format("%s | v%s (%s)", NAME, VERSION, VERSION_NAME) # "Cyberarm's W3D Hub Linux Launcher | v2.0.0 alpha"

      @main_thread_queue = []

      push_state(States::Boot)
      # push_state(States::Interface)
    end

    def needs_redraw?
      states.any?(&:needs_repaint?)
    end

    def update
      while(block = @main_thread_queue.shift)
        block.call
      end

      WORKER.service

      super

      sleep 0.001
    end

    def add_to_queue(block)
      @main_thread_queue << block
    end
  end
end
