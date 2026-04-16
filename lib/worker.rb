module W3DHubLauncher
  class Worker
    def initialize
      @threads = []

      # listen for requests from frontend
      listener = Thread.new { listen }
      # connect to and monitor GSH web service
      @threads << Thread.new { game_server_hub_websocket }
      # connect to and monitor Backend web service
      @threads << Thread.new { backend_websocket }

      listener.join
    end

    def listen
      loop do
        request = Ractor.receive
        pp request
      end
    end

    def game_server_hub_websocket
    end

    def backend_websocket
    end
  end
end
