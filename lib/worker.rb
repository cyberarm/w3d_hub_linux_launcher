module W3DHubLauncher
  class Worker
    Response = Data.define(:status, :request_id, :data)

    def initialize
      @threads = []
      @requests = []

      @settings = # Settings.new

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

        if respond_to?(query.type)
          Async do
            send(query.type, query)
          end
        else
          raise "UNKNOWN REQUEST: #{query}"
        end
      end
    end

    def game_server_hub_websocket
    end

    def backend_websocket
    end

    #
    # ------------ query / request handlers ------------
    #
    def fetch_url(query)
    end

    def download_url(query)
    end

    def w3dhub_api_call(query)
      result = @w3dhub_api.send(query.data[:call], *(query.data[:arguments] || []))
      pp result
      response = Response.new(result.okay? ? Request::STATUS_COMPLETE : Request::STATUS_ERROR, query.request_id, result)

      Ractor.main.send(response)
    end

    def update_settings(query)
      result = CyberarmEngine::Result.new

      FileUtils.mkdir_p(W3DHubLauncher::CONFIG_PATH) # FIXME: FAILABLE!
      File.write("#{W3DHubLauncher::CONFIG_PATH}/settings.json", query.data) # FIXME: FAILABLE!
      result.data = query.data
      response = Response.new(result.okay? ? Request::STATUS_COMPLETE : Request::STATUS_ERROR, query.request_id, result)

      Ractor.main.send(response)
    end

    def install_application(query)
    end

    def update_application(query)
    end

    def repair_application(query)
    end

    def move_application(query)
    end

    def uninstall_application(query)
    end
  end
end
