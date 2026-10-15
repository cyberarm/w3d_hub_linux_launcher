module W3DHubLauncher
  class Window < CyberarmEngine::Window
    def setup
      self.show_cursor = true
      self.caption = format("%s | v%s (%s)", NAME, VERSION, VERSION_NAME) # "Cyberarm's W3D Hub Linux Launcher | v2.0.0 alpha"

      @main_thread_queue = []

      CyberarmEngine::EventBus.subscribe("game_server_pings", self) do |payload|
        MemCache[:game_server_pings] = payload
      end

      CyberarmEngine::EventBus.subscribe("game_server_list", self) do |payload|
        MemCache[:servers] = payload.map { |server| Worker::Api::GameServer.new(server) }
      end

      CyberarmEngine::EventBus.subscribe("game_server_added", self) do |payload|
        existing_game_server = MemCache[:servers]&.find { |s| s.id == payload["id"] }
        game_server = Worker::Api::GameServer.new(payload)

        if existing_game_server
          MemCache[:servers][MemCache[:servers].index(existing_game_server)] = game_server
        else
          MemCache[:servers] ||= []
          MemCache[:servers] << game_server
        end
      end

      CyberarmEngine::EventBus.subscribe("game_server_updated", self) do |payload|
        existing_game_server = MemCache[:servers]&.find { |s| s.id == payload["id"] }
        game_server = Worker::Api::GameServer.new(payload)

        if existing_game_server
          MemCache[:servers][MemCache[:servers].index(existing_game_server)] = game_server
        else
          MemCache[:servers] ||= []
          MemCache[:servers] << game_server
        end
      end

      CyberarmEngine::EventBus.subscribe("game_server_removed", self) do |payload|
        game_server = MemCache[:servers]&.find { |s| s.id == payload["id"] }

        MemCache[:servers].delete(game_server) if game_server
      end

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
