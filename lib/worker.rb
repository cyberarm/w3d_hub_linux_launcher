module W3DHubLauncher
  class Worker
    Response = Data.define(:status, :request_id, :data)

    def initialize
      @threads = []
      @requests = []

      # next available request_id to assign incoming requests
      @request_id = 0

      # listen for requests from frontend
      listener = Thread.new { listen }
      # connect to and monitor GSH web service
      @threads << Thread.new { game_server_hub_websocket }
      # connect to and monitor Backend web service
      @threads << Thread.new { backend_websocket }

      @w3dhub_api = W3DHubLauncher::W3DHubApi.new

      listener.join
    end

    def listen
      loop do
        query = Ractor.receive
        pp query

        case query.type
        when Request::FETCH_URL
        when Request::DOWNLOAD_URL
        when Request::W3DHUB_API_CALL
          Async do
            result = @w3dhub_api.send(query.data[:call], *(query.data[:arguments] || []))
            response = Response.new(result.okay? ? Request::STATUS_COMPLETE : Request::STATUS_ERROR, query.request_id, result)
            Ractor.main.send(response)
          end
        else
          raise "UNKNOWN REQUEST"
        end
      end
    end

    def game_server_hub_websocket
    end

    def backend_websocket
    end
  end
end
